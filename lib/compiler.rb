class Story
  VALID_FORMATS = %w{html pdf}
  VALID_STYLES = %w{default}

  attr_reader :passage_index, :link_text

  def initialize(html, link_text: "{{text}} (turn to <strong>{{link}}</strong>)")
    doc = Nokogiri::HTML(html)
    raise 'Twine Story not found' unless story = doc.css('tw-storydata')[0]
    @name = story['name']
    @start_node = story['startnode'].to_i
    @passages, @special_pre_passages, @special_post_passages = [], [], []
    story.css('tw-passagedata').each do |p|
      new_passage = Passage.new(p, self)
      if new_passage.tags.include?('twinebook-pre')
        @special_pre_passages.push new_passage
      elsif new_passage.tags.include?('twinebook-post')
        @special_post_passages.push new_passage
      else
        @passages.push new_passage
      end
    end
    @link_text = link_text
  end

  def passage(identifier)
    return @passages.find{|p|p.pid == identifier} if identifier.is_a? Integer
    @passages.find{|p|p.name == identifier}
  end

  def output(format: 'html', style: 'default')
    # sanity checks
    raise ArgumentError unless VALID_FORMATS.include?(format) && VALID_STYLES.include?(style)
    # Shuffle passages then ensure the start one is at the start
    @passages.shuffle!
    start_passage = passage(@start_node)
    start_passage_index = @passages.index(start_passage)
    @passages[0], @passages[start_passage_index] = @passages[start_passage_index], @passages[0]
    # Any other passages that really want to be particular numbers get to be by swapping them around
    @passages.select{|p|p.preferred_number}.each do |passage|
      currently_at = @passages.find_index(passage)
      @passages[passage.preferred_number], @passages[currently_at] = @passages[currently_at], @passages[passage.preferred_number]
    end
    # Build an index of passage numbers for cross-referencing (and adjust from 0-indexed to 1-indexed numbers)
    @passage_index = {}
    @passages.each_with_index{|p,i| @passage_index[p.name] = i+1}
    # style
    @css = File.read("templates/#{style}.css")
    # output
    html = ERB.new(File.read('templates/story.html')).result binding
    if format == 'html'
      return html
    elsif format == 'pdf'
      out, err, status = Open3.capture3(
        "wkhtmltopdf -q -s A4 -O portrait - -",
        stdin_data: html
      )
      raise err unless status.exitstatus == 0
      return out
    end
  end
end

class Link
  def initialize(text, link, story)
    @text, @link, @story = text, link, story
  end

  def to_s
    link_destination = @story.passage_index[@link]
    @story.link_text.gsub('{{text}}', @text).gsub('{{link}}', link_destination.to_s)
  end
end

class Passage
  attr_reader :name, :pid, :content, :story, :tags

  def initialize(node, story)
    @story = story
    @pid = node['pid'].to_i
    @name = node['name']
    @tags = (node['tags'] || '').split(/\s+/)
    @content = node.content
  end

  def preferred_number
    return false unless tag = self.tags.find{|tag|tag =~ /always-(\d+)/}
    $1.to_i - 1
  end

  def rendered_content
    html = Kramdown::Document.new(@content).to_html
    html.gsub!(/\[\[((?<text>[^\]]+?)(\||-&gt;)(?<link>[^\]]+?)|(?<link>[^\]]+?)&lt;-(?<text>[^\]]+?))\]\]/){ Link.new($~[:text], $~[:link], @story) }
    html
  end

  def output
    @title = if self.tags.include?('twinebook-pre') || self.tags.include?('twinebook-post')
      nil
    else
      @story.passage_index[@name]
    end
    ERB.new(File.read('templates/passage.html')).result binding
  end
end
## Twinebook

Product printable PDF gamesbooks from simple Twine hypertext games. Prototype. Available online at https://twinebook.danq.dev/.

### Purpose

[Twine 2](https://twinery.org/2/) provides a sophisticated platform for developing "choose your own adventure"-style games in hypertext format. I've long thought that its features would also be great for writing traditional printed gamebooks, if only the tools existed to export in an appropriate format. This project aims to fill that gap.

Produce a simple game using Twine 2, export is as a playable HTML file, and then run it through Twinebook to produce a PDF version of your adventure, complete with "turn to 26"-style cross-references instead of hyperlinks.

### Usage

You can use this tool at https://twinebook.danq.dev/.

To self-host, you'll need Ruby and the dependencies to run [wkhtmltopdf](https://wkhtmltopdf.org/). Check out the codebase, `bundle` to get the gems. Then run `ruby twinebook.rb` to launch a local server, or deploy in your favourite Rack-friendly server (Twinebook is powered by Sinatra).

### Future?

This is an experimental/prototype project providing the minimum level of features to assess whether it's worthwhile continuing. Feedback is very welcome!

### License

Open source under the GNU General Public License v3.0.

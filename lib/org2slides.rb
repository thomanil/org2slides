# -*- coding: utf-8 -*-
module OrgToSlides
  VERSION = "0.2.0"


  class Converter

    def body(orgfile_path)
      `cat #{orgfile_path}`
    end

    def title(orgfile_path)
      `cat #{orgfile_path} | grep "#+TITLE:" `.gsub("#+TITLE:", "").strip
    end

    def layout(title, body)
      <<MARKUP
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>#{title}</title>
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
    <link href='http://fonts.googleapis.com/css?family=Lato:400,700,400italic,700italic' rel='stylesheet' type='text/css'>
    <link rel="stylesheet" href="css/main.css">
    <link rel="stylesheet" href="css/theme/default.css">
    <!-- For syntax highlighting -->
    <link rel="stylesheet" href="lib/css/zenburn.css">
    <script>
      // If the query includes 'print-pdf' we'll use the PDF print sheet
      document.write( '<link rel="stylesheet" href="css/print/' + ( window.location.search.match( /print-pdf/gi ) ? 'pdf' : 'paper' ) + '.css" type="text/css" media="print">' );
    </script>
    <!--[if lt IE 9]>
        <script src="lib/js/html5shiv.js"></script>
    <![endif]-->
  </head>
  <body>
    <div class="reveal">
      <!-- Used to fade in a background when a specific slide state is reached -->
      <div class="state-background"></div>

      <!-- Any section element inside of this container is displayed as a slide -->
      <div class="slides">

      #{body}

      </div>

      <!-- The navigational controls UI -->
      <aside class="controls">
        <a class="left" href="#">&#x25C4;</a>
        <a class="right" href="#">&#x25BA;</a>
        <a class="up" href="#">&#x25B2;</a>
        <a class="down" href="#">&#x25BC;</a>
      </aside>
      <!-- Presentation progress bar -->
      <div class="progress"><span></span></div>
    </div>
    <script src="lib/js/head.min.js"></script>
    <script src="js/reveal.min.js"></script>
    <script>
      // Full list of configuration options available here:
      // https://github.com/hakimel/reveal.js#configuration
      Reveal.initialize({
          controls: true,
          progress: true,
          history: true,
          transition: Reveal.getQueryHash().transition || 'linear', // default/cube/page/concave/linear(2d)
          // Optional libraries used to extend on reveal.js
          dependencies: [
              { src: 'lib/js/highlight.js', async: true, callback: function() { window.hljs.initHighlightingOnLoad(); } },
              { src: 'lib/js/classList.js', condition: function() { return !document.body.classList; } },
              { src: 'lib/js/showdown.js', condition: function() { return !!document.querySelector( '[data-markdown]' ); } },
              { src: 'lib/js/data-markdown.js', condition: function() { return !!document.querySelector( '[data-markdown]' ); } },
              { src: 'socket.io/socket.io.js', async: true, condition: function() { return window.location.host === 'localhost:1947'; } },
              { src: 'plugin/speakernotes/client.js', async: true, condition: function() { return window.location.host === 'localhost:1947'; } },
          ]
      });
    </script>
  </body>
</html>
MARKUP
    end

    def convert_old(orgfile_path)
      title = "" # TODO derive title from filename and|or org contents
      puts `org2html #{orgfile_path}`
      htmlfile_path = orgfile_path.gsub(".org", ".html")
      htmldir_name = orgfile_path.gsub(".org", "")
      body = body(htmlfile_path)
      body = transform_divs_into_sections(body)
      body = slide_layout(title, body)

      # TODO use path of this file to find dir of template dir where gem is actually located

      gem_root_path = File.expand_path(File.dirname(__FILE__))+"/.."
      `cp -r #{gem_root_path}/templates/reveal_js_template #{htmldir_name}_generated_slides`
      File.open("#{htmldir_name}_generated_slides/index.html", 'w') { |file| file.write(body) }
      `rm #{htmlfile_path}`
      return htmldir_name
    end

    def ast_to_reveal_js_structure(ast)
      slides = []

      # TODO: run to_html on ruby parser ast first, or can we do it after?

      ast.headlines.each do |h|
        slide_title =  h.body_lines[0].to_s
        slide_body = h.body_lines[1..(h.body_lines.size-1)].map{|l| l.to_s}.join("\n")
        slides << {:title => slide_title, :body => slide_body}
      end

      puts slides
    end

    def convert(orgfile_path)

      org_body = contents = File.read(orgfile_path)
      ast = Orgmode::Parser.new(org_body)
      slide_markup_body = ast.to_revealjs_html

      title = "" # TODO derive title from filename and|or org contents
      full_body = layout(title, slide_markup_body)

      #puts body

      htmldir_name = orgfile_path.gsub(".org", "")
      gem_root_path = File.expand_path(File.dirname(__FILE__))+"/.."
      `cp -r #{gem_root_path}/templates/reveal_js_template #{htmldir_name}_generated_slides`
      File.open("#{htmldir_name}_generated_slides/index.html", 'w') { |file| file.write(full_body) }
      return htmldir_name
    end

  end
end



# For now, monkeypath in revealjs export into the org-ruby lib

require 'org-ruby'


module Orgmode
  class Parser

    @first_slide_done = false

    def translate_to_slides(lines, output_buffer)
      output_buffer.output_type = :start
      lines.each do |line|
        if (line.kind_of?(Headline))

          if(!@first_slide_done)
            @first_slide_done = true
          else
            output_buffer.insert_slide_stop
          end

          output_buffer.insert_slide_start
        end
        output_buffer.insert(line)
      end
      output_buffer.flush!
      output_buffer.pop_mode while output_buffer.current_mode
      output_buffer.output_footnotes!
      output_buffer.output
    end

    def to_revealjs_html
      mark_trees_for_export
      export_options = {
        :decorate_title        => @in_buffer_settings["TITLE"],
        :export_heading_number => export_heading_number?,
        :export_todo           => export_todo?,
        :use_sub_superscripts  => use_sub_superscripts?,
        :export_footnotes      => export_footnotes?,
        :link_abbrevs          => @link_abbrevs,
        :skip_syntax_highlight => @parser_options[:skip_syntax_highlight],
        :markup_file           => @parser_options[:markup_file]
      }
      export_options[:skip_tables] = true if not export_tables?
      output = ""
      output_buffer = RevealJsHtmlBuffer.new(output, export_options)

      if @in_buffer_settings["TITLE"]

        # If we're given a new title, then just create a new line
        # for that title.
        title = Line.new(@in_buffer_settings["TITLE"], self, :title)
        translate_to_slides([title], output_buffer)
      end
      translate_to_slides(@header_lines, output_buffer) unless skip_header_lines?

      # If we've output anything at all, remove the :decorate_title option.
      export_options.delete(:decorate_title) if (output.length > 0)
      @headlines.each do |headline|
        next if headline.export_state == :exclude
        case headline.export_state
        when :exclude
        # NOTHING
        when :headline_only
          translate_to_slides(headline.body_lines[0, 1], output_buffer)
        when :all
          translate_to_slides(headline.body_lines, output_buffer)
        end
      end
      output << "\n"

      return output if @parser_options[:skip_rubypants_pass]

      rp = RubyPants.new(output)

      unclosed_html = rp.to_html
      closed_html = unclosed_html << "END-SLIDE"
      sectioned_html = closed_html.gsub("START-SLIDE", "\n<section>").gsub("END-SLIDE","\n</section>")
    end
  end


  class RevealJsHtmlBuffer < HtmlOutputBuffer
    def insert_slide_start
      @buffer << "START-SLIDE"
    end

    def insert_slide_stop
      @buffer << "END-SLIDE"
    end

    def insert(line)
      # Prepares the output buffer to receive content from a line.
      # As a side effect, this may flush the current accumulated text.
      @logger.debug "Looking at #{line.paragraph_type}|#{line.assigned_paragraph_type}(#{current_mode}) : #{line.to_s}"

      # We try to get the lang from #+BEGIN_SRC blocks
      @block_lang = line.block_lang if line.begin_block?
      unless should_accumulate_output?(line)
        flush!
        maintain_mode_stack(line)
      end


      # Adds the current line to the output buffer
      case
      when line.assigned_paragraph_type == :comment
      # Don't add to buffer
      when line.title?
        @buffer << line.output_text
      when line.raw_text?
        @buffer << "\n" << line.output_text if line.raw_text_tag == @buffer_tag
      when preserve_whitespace?
        @buffer << "\n" << line.output_text unless line.block_type
      when line.assigned_paragraph_type == :code
      # If the line is contained within a code block but we should
      # not preserve whitespaces, then we do nothing.
      when (line.kind_of? Headline)
        add_line_attributes line
        @buffer << "\n" << line.output_text.strip
      when ([:definition_term, :list_item, :table_row, :table_header,
             :horizontal_rule].include? line.paragraph_type)
        @buffer << "\n" << line.output_text.strip
      when line.paragraph_type == :paragraph
        @buffer << "\n"
        buffer_indentation
        @buffer << line.output_text.strip
      end

      if mode_is_code? current_mode and not line.block_type
        # Determines the amount of whitespaces to be stripped at the
        # beginning of each line in code block.
        if line.paragraph_type != :blank
          if @code_block_indent
            @code_block_indent = [@code_block_indent, line.indent].min
          else
            @code_block_indent = line.indent
          end
        end
      end

      @output_type = line.assigned_paragraph_type || line.paragraph_type
    end
  end

end

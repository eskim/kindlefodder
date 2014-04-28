# http://regex.learncodethehardway.org/book/

require 'kindlefodder'

class HardwayRegex < Kindlefodder

  def get_source_files
    sections = extract_sections
    File.open("#{output_dir}/sections.yml", 'w') {|f|
      f.puts sections.to_yaml
    }
  end

  def document
    if !File.size?("cover.gif")
      `curl -s 'http://zedshaw.com/images/logo.png' > cover.png`
      # run_shell_command "convert cover.png -resize '400x300>' cover.gif"
    end

    {
      'title' => 'Learn Regex The Hard Way',
      'author' => 'Zed. A. Shaw',
      'cover' => "cover.png",
      'masthead' => "cover.png"
    }
  end

  def save_article filename
    path = "articles/#{filename}"
    return path if File.size?("#{output_dir}/#{path}")
    url = @base_url + filename
    html = run_shell_command("curl -s #{url}")
    doc = Nokogiri::HTML utf8(html)



    doc.search("script").map &:remove
    doc.search(".navheader").map &:remove
    doc.search(".navfooter").map &:remove
    doc.search(".toc").each &:remove

    # images have relative paths, so fix them
    doc.search("img[@src]").each {|img|
      if img['src'] !~ %r{^http}
        img['src'] = @base_url + img['src']
      end
    }


    doc.search("div.eleven h1").each {|h1|
      h1.name = "h3"
    }

    wrapper = Nokogiri::XML("<div></div>").at("div")
    wrapper << doc.at("h1")
    wrapper << doc.at("div.eleven")


    # content = doc.at('body').inner_html



    content = wrapper.to_html
    File.open("#{output_dir}/#{path}", 'w'){|f| f.puts content}
    path
  end


  def extract_sections

    @base_url = 'http://regex.learncodethehardway.org/book/'
    html = run_shell_command "curl -s #{@base_url}"
    doc = Nokogiri::HTML utf8(html)

    xs = []  # the sections
    articles = []
    section = {
      title: 'Learn Regex The Hard Way',
    }

    tocs = doc.css("#table-of-contents li a")
    tocs.each do |a|
      title = a.inner_text
      path = save_article(a['href'])
      articles << {title: title, path: path}
    end

    section[:articles] = articles
    xs << section
    xs

    # frontmatter_section = {
    #   title: 'Frontmatter',
    #   articles: [ { title: 'Title Page', path: titlepage(doc) }, { title: 'Dedication', path: dedication(doc) } ]
    # }
    # xs << frontmatter_section
    # doc.search('.toc a').select {|a| a['href'] =~ /html$/}.each {|a|

    #   if a.inner_text =~ /^Glossary/
    #     xs << { title: "Appendix", articles:[ ] }
    #   elsif a.inner_text =~ /^Rootless/
    #     xs << { title: "Unix Koans", articles:[ ] }
    #   end

    #   if a[:href] =~ /(preface|chapter)\.html/
    #     # looks like a section
    #     xs << {
    #       title: a.inner_text,
    #       articles:[
    #         {
    #           title: a.inner_text.gsub(/\s{2,}/, ' ').strip,
    #           path: save_article(a[:href])
    #         }
    #       ]
    #     }
    #   else
    #     # add an article
    #     xs.last[:articles] << {title: a.inner_text.gsub(/\s{2,}/, ' ').strip, path: save_article(a[:href])}
    #   end
    # }
    # xs
  end

  def titlepage(doc)
    path = 'articles/titlepage'
    content = doc.at('.titlepage').inner_html
    File.open("#{output_dir}/#{path}", 'w'){|f| f.puts content}
    path
  end

  def dedication(doc)
    path = 'articles/dedication'
    content = doc.at('.dedication').inner_html
    File.open("#{output_dir}/#{path}", 'w'){|f| f.puts content}
    path
  end


  def fixup_html! item
    # extract content out of table.blockquote
    item.search("div.blockquote").each {|x|
      x.inner_html = "<blockquote>" + x.search("td").map {|td| td.inner_html}.join("\n") + "</blockquote>"
    }
    # wrap .epigraph content in blockquotes
    item.search(".epigraph").each {|x|
      x.inner_html = "<blockquote>" + x.inner_html + "</blockquote>"
    }
    item.search("span.attribution").each {|x|
      x['style'] = "font-style:italic"
    }

    item.search('div.titlepage').each {|x|
      if x.at('table')
        x.inner_html = x.search("td").map {|td| td.inner_html}.join("\n")
      end
    }

    # remove nested p's in li's
    item.search('li p').each {|p| p.swap Nokogiri::XML::Text.new(p.inner_text, item) }

    item.search('div.mediaobject').each {|x| x.name = 'p'}

  end

  def utf8 s
    if s.force_encoding("iso-8859-1").valid_encoding?
      s.encode 'utf-8'
    else
      s
    end
  end
end

HardwayRegex.generate

require 'kindlefodder'

class ProgInScala < Kindlefodder

  def get_source_files
    start_url = 'http://www.artima.com/pins1ed/indexP.html'

    @start_doc = Nokogiri::HTML run_shell_command("curl -s -L #{start_url}")

    File.open("#{output_dir}/sections.yml", 'w') {|f|
      f.puts extract_sections.to_yaml
    }
  end

  # This method is for the ebook metadata.
  def document
    {
      'title' => 'Programming in Scala, First Ed.',
      'cover' => nil,
      'masthead' => nil,
    }
  end


  def extract_sections
    sec = @start_doc.search('#toc a').map do |o|
      title = o.inner_text

      $stderr.puts "#{title}"

      FileUtils::mkdir_p "#{output_dir}/articles"

      {
        title: title,
        articles: [get_article(o[:href])]
      }
    end

    sec.delete_if { |s| s[:title].to_i == 0 }
    sec
  end

  def get_article(article_ref)
    article_html = run_shell_command "curl -s -L http://www.artima.com/pins1ed/#{article_ref.gsub(/\./, "P.")}"

    article_doc = Nokogiri::HTML(article_html)

    article = article_doc.search('div.vegies')

    title = article.search('.tc .ts').text.strip

    article.search('img').each { |img|
      img['src'] = 'http://www.artima.com/pins1ed/' + img['src']
    }
    $stderr.puts "- #{title}"

    # if toc = article.at('#toc0')
    #   toc.remove
    # end

    # article.search('a').each do |link|
    #   if link[:href] =~ /\/\//
    #     link.name = 'strong'
    #   end
    # end

    # article.search('br').each do |br|
    #   if br.next && br.next.name == 'br'
    #     br.remove
    #   end
    # end

    article_body = article.inner_html
    path = "articles#{article_ref}.html"

    File.open("#{output_dir}/#{path}", 'w') do |f|
      f.puts article_body
    end

    {
      title: title,
      path: path,
      description: '',
      author: ''
    }
  end

end

# RUN IT! This pulls down the documentation and turns it into the Kindle ebook.

ProgInScala.generate

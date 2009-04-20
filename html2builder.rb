require 'rubygems'
require 'nokogiri'

class HTMLToBuilder

  def initialize src,out
    @doc = Nokogiri::HTML.parse(src)
    @out = out
    @indent = 2
    @cssproxy = true
  end

  def out level, *args
    puts (" "*(level*@indent))+args.join
  end

  def process_node node, level = 0
    case node.name
    when "#cdata-section","text"
      if (node.to_html.strip  != "")
        lines = node.to_html.strip.split("\n")
        if lines.size > 1
          out level,"text <<-END_TEXT"
          lines.each {|line| out level,line }
          out level,"END_TEXT"
        else
          out level, "text \"#{lines[0]}\""
        end
      end
    when "comment"
      # ignore
    else
      a = node.attributes.dup
      if @cssproxy
        cssid = a["id"]
        cssclass = a["class"]
        a.delete("class")
        a.delete("id")
      end
      
      raw_attrs = a.collect {|k,v| "#{k.to_sym.inspect} => \"#{v.inspect}\""}

      if raw_attrs.size > 0
        attrs = "(#{raw_attrs.join(", ")})"
      else
        attrs = ""
      end

      name = "#{node.name}#{cssid ? "."+cssid+"!" : ""}#{cssclass ? "."+cssclass : ""}"

      if node.children.size > 0
        if node.children.size == 1 && node.children[0].name == "text"
          args = []
          args << "{#{raw_attrs.join(", ")}}" if raw_attrs.size > 0
          args << "\"#{node.children[0].to_html.strip}\""
          out level,"#{name}(#{args.join(", ")})"
        else
          out level,"#{name}#{attrs} do"
          node.children.each {|n| process_node(n,level+1) }
          out level,"end"
        end
      else
        out level,"#{name}#{attrs}"
      end
    end
  end

  def process
    process_node(@doc.root)
  end
end

h = HTMLToBuilder.new(ARGF,STDOUT)
h.process

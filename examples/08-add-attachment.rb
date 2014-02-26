#! /usr/bin/env ruby

# To build an ocra package for windows
# ocra .\08-add-attachment.rb .\earthjello.jpeg

require 'pp'
require 'base64'
require 'rally_api'
require 'highline'
require 'highline/import'

#Configuration for rally connection specified in 00-config.rb
require_relative '00-config'

choose do |menu|
  menu.prompt = "Please choose your Rally environment:"
  menu.choice(:sandbox) do
    @config[:base_url] = "https://sandbox.rallydev.com/slm"
    say("You chose sandbox.")
  end
  menu.choice(:rally1) do
    @config[:base_url] = "https://rally1.rallydev.com/slm"
    say("You chose production.")
  end
end

@config[:username]  = ask("Enter your Rally username: "){|q| q.echo = true}
@config[:password]  = ask("Enter your Rally password: "){|q| q.echo = "*"}
@config[:workspace] = ask("Enter your Rally workspace: "){|q| q.echo = true}
@config[:project]   = ask("Enter your Rally project: "){|q| q.echo = true}

iterations = ask("Enter the number of defects you would like to create (each with two attachments)?", Integer) { |q| q.in = 0..10000}


puts "Username entered: " + @config[:username]
puts "Workspace entered: " + @config[:workspace]
puts "Project entered: " + @config[:project]

jpg_file_name = "earthjello.jpeg"
jpg_file_path =  File::join(File.dirname(__FILE__),jpg_file_name)

def show_some_values(title, defect)
  values = ["Name", "CreationDate", "FormattedID","Attachments"]
  format = "%-12s : %s"

  puts "-" * 80
  puts title
  values.each do |field_name|
    if defect[field_name].class == RallyAPI::RallyCollection
      puts format % [field_name," "]
      defect[field_name].each do |value|
        puts format % [" ",value._refObjectName]
      end
    else
      puts format % [field_name, defect[field_name]]
    end
  end
end

def create_content(rally, content_string)
  begin
    content_base64 = Base64.encode64(content_string)
    content_ref = rally.create(:attachmentcontent, {"Content" => content_base64})
    return content_ref
  rescue Exception => boom
    puts "*" * 80
    puts "Exception rescued in create_content:"
    puts "Exception: #{boom.class}"
    puts "Error Message: #{boom}"
    raise StandardError, 'create_content failure'
  end

end


def post_text_attachment(rally, artifact, file_name, text_content)
  begin
    content = create_content(rally, text_content)

    attachment_info = {}
    attachment_info["Name"] = file_name
    attachment_info["ContentType"] = "text/plain"
    attachment_info["Size"] = text_content.length
    attachment_info["Content"] = content
    attachment_info["Artifact"] = artifact.ref

    result = rally.create(:attachment, attachment_info)

  rescue Exception => boom
    puts "*" * 80
    puts "Exception rescued in post_text_attachment"
    puts "Exception: #{boom.class}"
    puts "Error Message: #{boom}"
    raise StandardError, 'post_text_attachment failure'
  end
end

def post_jpg_attachment(rally, artifact, file_name, file_path)
  begin

    image_data = File.open(file_path, 'rb') { |f| f.read }

    content = create_content(rally, image_data)

    attachment_info = {}
    attachment_info["Name"] = file_name
    attachment_info["ContentType"] = "image/jpeg"
    attachment_info["Size"] = image_data.length
    attachment_info["Content"] = content
    attachment_info["Artifact"] = artifact.ref

    result = rally.create(:attachment, attachment_info)

  rescue Exception => boom
    puts "*" * 80
    puts "Exception rescued in post_jpg_attachment"
    puts "Exception: #{boom.class}"
    puts "Error Message: #{boom}"
    raise StandardError, 'post_text_attachment failure'
  end
end


begin
  rally = RallyAPI::RallyRestJson.new(@config)

  iterations.times do |iteration|

    fields = {}
    fields["Name"] = "Test Defect ##{iteration+1} with attachment created at #{Time.now.utc()} with Rally API gem"
    fields["Priority"] = "High Attention"

    new_defect = rally.create("defect", fields)
    # show_some_values("Defect Fields", new_defect)

    post_text_attachment(rally, new_defect, "FirstAttachment.txt", "Attachment text for #{new_defect["FormattedID"]}")
    post_jpg_attachment(rally, new_defect, jpg_file_name, jpg_file_path)

    new_defect.read()
    show_some_values("Defect Fields with Attachments",new_defect)

  end

rescue Exception => boom
  puts "*" * 80
  puts "Rescued #{boom.class}"
  puts "Error Message: #{boom}"
end


#!/usr/bin/env ruby
# this executable populates the db with new resources.
# create_resource -t node -
BIN_DIR = File.dirname(File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__)
TOP_DIR = File.join(BIN_DIR, '..')
$: << File.join(TOP_DIR, 'lib')

DESCR = %{
POST a list of VLANs to Broker
}

require 'optparse'

begin; require 'json/jwt'; rescue Exception; end

comm_type = nil
resource_url = nil
domain = nil
vlans_list = nil
operation = nil
@ch_key = nil
@flowvisor_rc_topic = nil
@authorization = false
@entity = nil
@trusted_roots = nil
@cert = nil
@pkey = nil

op = OptionParser.new
op.banner = "Usage: #{op.program_name} --conf CONF_FILE --in INPUT_FILE...\n#{DESCR}\n"

op.on '-c', '--conf FILE', "Configuration file with communication info" do |file|
  require 'yaml'
  if File.exists?(file)
    @y = YAML.load_file(file)
  else
    error "No such file: #{file}"
    exit
  end

  if x = @y[:rest]
    require "net/https"
    require "uri"
    domain = x[:domain]
    resource_url = "https://#{x[:server]}:#{x[:port]}/resources/vlans"
    comm_type = "REST"
    @ch_key = File.read(x[:ch_key])
  else
    error "REST details was not found in the configuration file"
    exit
  end

  if a = @y[:auth]
    @pem = a[:entity_cert]
    @pkey = a[:entity_key]
  else
    warn "authorization is disabled."
    exit if comm_type == "REST"
  end
end

op.on '-d', '--domain (DOMAIN)', "You need to pass the domain of the institution" do |d|
  domain = d
end

op.on '-o', '--operation (DELETE|POST)', "You need to say if you want to post or delete a VLAN" do |op|
  operation = op
end

op.on '-v', '--vlans (VLANS NUMBERS)', "You need to pass a list a VLANS to POST/DELETE. The list can be a list of numbers seperated by comma or in this format: <first-vlan>:<last-vlan> " do |v|
  if v.match(/(?=.*:)(?=.*,)/)
    raise ArgumentError.new("Vlan list is not following the patterns")
  end

  new_vlans_list = []
  if v.include? ":"
    first_vlan = v.split(":")[0].strip.to_i
    last_vlan = v.split(":")[1].strip.to_i

    for vlan in first_vlan..last_vlan
      new_vlans_list.append(vlan)
    end
  elsif v.include? ","
    list = v.split(",")
    for vlan in list
      new_vlans_list.append(vlan.strip)
    end
  end
  vlans_list = new_vlans_list
end

op.on '-u', '--url (URL)', "You need to pass the Broker's URL" do |u|
  resource_url = u
end

rest = op.parse(ARGV) || []

def delete_resources_with_rest(url, res_desc, pem, key, ch_key)
  puts "Delete links through REST.\nURL: #{url}\nRESOURCE DESCRIPTION: \n#{res_desc}\n\n"

  uri = URI.parse(url)
  pem = File.read(pem)
  pkey = File.read(key)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.cert = OpenSSL::X509::Certificate.new(pem)
  http.key = OpenSSL::PKey::RSA.new(pkey)
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  request = Net::HTTP::Delete.new(uri.request_uri, initheader = {'Content-Type' =>'application/json'})
  request['CH-Credential'] = ch_key
  request.body = res_desc.to_json

  response = http.request(request)

  JSON.parse(response.body)
end

def create_resource_with_rest(url, type, res_desc, pem, key, ch_key)
  puts "Create #{type} through REST.\nURL: #{url}\nRESOURCE DESCRIPTION: \n#{res_desc}\n\n"

  uri = URI.parse(url)
  pem = File.read(pem)
  pkey = File.read(key)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.cert = OpenSSL::X509::Certificate.new(pem)
  http.key = OpenSSL::PKey::RSA.new(pkey)
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  request = Net::HTTP::Post.new(uri.request_uri, initheader = {'Content-Type' =>'application/json'})
  request['CH-Credential'] = ch_key
  request.body = res_desc.to_json

  response = http.request(request)

  puts "#{response.inspect}"
end

def authorization?
  @authorization
end

def delete_vlans(vlans_list, domain, resource_url)
  vlans_to_delete = []

  for vlan_num in vlans_list
    vlan_property = {
        :urn => "urn:publicid:IDN+#{domain}+vlan+#{vlan_num}"
    }
    vlans_to_delete.append(vlan_property)
  end

  delete_resource_with_rest("#{resource_url}/vlans", vlans_to_delete, @pem, @pkey, @ch_key)
end

def post_vlans(vlans_list, domain, resource_url)

  for vlan_num in vlans_list
    new_vlan = {
        :urn => "urn:publicid:IDN+#{domain}+vlan+#{vlan_num}",
        :number => "#{vlan_num}",
        :name => "#{vlan_num}"
    }
    create_resource_with_rest("#{resource_url}", "vlans", new_vlan, @pem, @pkey, @ch_key)
  end
end

[:domain, :operation, :vlans_list, :resource_url].each {|param|
  puts eval(param.to_s)
  unless eval(param.to_s)
    raise OptionParser::MissingArgument.new("You need to specify a #{param}")
  end
}

if operation == "POST"
  post_vlans(vlans_list, domain, resource_url)
elsif operation == "DELETE"
  delete_vlans(vlans_list, domain, resource_url)
end
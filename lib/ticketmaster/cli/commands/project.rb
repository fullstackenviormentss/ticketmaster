require 'rubygems'
# The command method call for project
# This sets the option parser and passes the parsed options to the subcommands
def project(options)
  ARGV << '--help' if ARGV.length == 0
  begin
    OptionParser.new do |opts|
      opts.banner = 'Usage: tm -p PROVIDER [options] project [project_options]'
      opts.separator ''
      opts.separator 'Options:'
      
      opts.on('-C', '--create ATTRIBUTES', 'Create a new project') do |attribute|
        options[:project_attributes] = {attribute => ARGV.shift}.merge(attributes_hash(ARGV))
        options[:subcommand] = 'create'
      end
      
      opts.on('-R', '--read [PROJECT]', 'Read out project and its attributes') do |id|
        options[:project] = id if id
        options[:subcommand] = 'read'
      end
      
      opts.on('-U', '--update ATTRIBUTES', 'Update project information') do |attribute|
        options[:project_attributes] = {attribute => ARGV.shift}.merge(attributes_hash(ARGV))
        options[:subcommand] = 'update'
      end
      
      opts.on('-D', '--destroy [PROJECT]', 'Destroy the project. Not reversible!') do |id|
        options[:project] = id if id
        options[:subcommand] = 'destroy'
      end
      
      opts.on('-I', '--info [PROJECT_ID]', 'Get project info. Same as --read. ') do |id|
        options[:project] = id if id
        options[:subcommand] = 'read'
      end
      
      opts.on('-S', '--search [ATTRIBUTES]', 'Search for a project based on attributes') do |attribute|
        options[:project_attributes] = attribute ? {attribute => ARGV.shift}.merge(attributes_hash(ARGV)) : {}
        options[:subcommand] = 'search'
      end
      
      opts.on('-L', '--list-all', 'List all projects. Same as --search without any parameters') do
        options[:project_attributes] = {}
        options[:subcommand] = 'search'
      end
      
      opts.on('-P', '--project [PROJECT_ID]', 'Set the project id') do |id|
        options[:project] = id
      end
      
      opts.separator ''
      opts.separator 'Other options:'
      
      opts.on_tail('-h', '--help', 'Show this message') do
        puts opts
        exit
      end
    end.order!
  rescue OptionParser::MissingArgument => exception
    puts "tm #{options[:original_argv].join(' ')}\n\n"
    puts "Error: An option was called that requires an argument, but was not given one"
    puts exception.message
  end
  parse_config!(options)
  begin
    require 'ticketmaster'
    require "ticketmaster-#{options[:provider]}"
  rescue
    require options[:provider]
  end
  send(options[:subcommand], options)
end


# The create subcommand
def create(options)
  tm = TicketMaster.new(options[:provider], options[:authentication])
  project = tm.project.create(options[:project_attributes])
  read_project project
  exit
end

# The read subcommand
def read(options)
  tm = TicketMaster.new(options[:provider], options[:authentication])
  project = tm.project.find(options[:project])
  read_project project
  exit
end

# The update subcommand
def update(options)
  tm = TicketMaster.new(options[:provider], options[:authentication])
  project = tm.project.find(options[:project])
  if project.update!(options[:project_attributes])
    puts "Successfully updated Project #{project.name} (#{project.id})"
  else
    puts "Sorry, it seems there was an error when trying to update the attributes"
  end
  read_project project
  exit
end

# The destroy subcommand.
def destroy(options)
  tm = TicketMaster.new(options[:provider], options[:authentication])
  project = tm.project.find(options[:project])
  puts "Are you sure you want to delete Project #{project.name} (#{project.id})? (yes/no) [no]"
  ARGV.clear
  confirm = readline.chomp.downcase
  if confirm != 'y' and confirm != 'yes'
    puts "Did not receive a 'yes' confirmation. Exiting..."
    exit
  elsif project.destroy
    puts "Successfully deleted Project #{project.name} (#{project.id})"
  else
    puts "Sorry, it seems there was an error when trying to delete the project"
  end
  exit
end

# The search and list subcommands
def search(options)
  tm = TicketMaster.new(options[:provider], options[:authentication])
  projects = tm.projects(options[:project_attributes])
  puts "Found #{projects.length} projects"
  projects.each_with_index do |project, index|
    puts "#{index+1}) Project #{project.name} (#{project.id})"
    #read_project project
    #puts
  end
  exit
end

# A utility method used to output project attributes
def read_project(project)
  project.system_data[:client].attributes.sort.each do |key, value|
    puts "#{key} : #{value}"
  end
end

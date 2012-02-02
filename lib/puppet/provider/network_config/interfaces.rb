# = Debian network_config provider
#
# This provider performs all real operations at the prefetch and flush stages
# of a puppet transaction, so the create, exists?, and destroy methods merely
# update the state that the resources should be in upon flushing.
require 'puppet/provider/isomorphism'

Puppet::Type.type(:network_config).provide(:interfaces) do

  include Puppet::Provider::Isomorphism
  self.file_path = '/etc/network/interfaces'

  desc "Debian interfaces style provider"

  confine    :osfamily => :debian
  defaultfor :osfamily => :debian

  def create
    super
    # If we're creating a new resource, assume reasonable defaults.
    # TODO remove this when more complete properties are defined in the type
    @property_hash[:attributes] = {:iface => {:family => "inet", :method => "dhcp"}, :auto => true}
  end

  mk_resource_methods # Instantiate accessors for resource properties

  def self.parse_file
    # Debian has a very irregular format for the interfaces file. The
    # parse_file method is somewhat derived from the ifup executable
    # supplied in the debian ifupdown package. The source can be found at
    # http://packages.debian.org/squeeze/ifupdown

    malformed_err_str = "Malformed debian interfaces file; cannot instantiate network_config resources"

    # The debian interfaces implementation requires global state while parsing
    # the file; namely, the stanza being parsed as well as the interface being
    # parsed.
    status = :none
    current_interface = nil
    iface_hash = {}

    lines = filetype.read.split("\n")
    # TODO line munging
    # Join lines that end with a backslash
    # Strip comments?

    # Iterate over all lines and determine what attributes they create
    lines.each do |line|

      # Strip off any trailing comments
      line.sub!(/#.*$/, '')

      case line
      when /^\s*#|^\s*$/
        # Ignore comments and blank lines
        next

      when /^allow-|^auto/

        # parse out allow-* and auto stanzas.

        interfaces = line.split(' ')
        property = interfaces.delete_at(0).intern

        interfaces.each do |iface|
          iface = iface
          iface_hash[iface] ||= {}
          iface_hash[iface][property] = true
        end

        # Reset the current parse state
        current_interface = nil

      when /^iface/

        # Format of the iface line:
        #
        # iface <iface> <family> <method>
        # zero or more options for <iface>

        if line =~ /^iface (\S+)\s+(\S+)\s+(\S+)/
          iface  = $1
          family = $2
          method = $3

          status = :iface
          current_interface = iface

          # If an iface block for this interface has been seen, the file is
          # malformed.
          if iface_hash[iface] and iface_hash[iface][:iface]
            raise Puppet::Error, malformed_err_str
          end

          iface_hash[iface] ||= {}
          iface_hash[iface][:iface] = {:family => family, :method => method, :options => []}

        else
          # If we match on a string with a leading iface, but it isn't in the
          # expected format, malformed blar blar
          raise Puppet::Error, malformed_err_str
        end

      when /^mapping/

        # XXX dox
        raise Puppet::DevError, "Debian interfaces mapping parsing not implemented."
        status = :mapping

      else
        # We're currently examining a line that is within a mapping or iface
        # stanza, so we need to validate the line and add the options it
        # specifies to the known state of the interface.

        case status
        when :iface
          if line =~ /(\S+)\s+(.*)/
            iface_hash[current_interface][:iface][:options] << line.chomp
          else
            raise Puppet::Error, malformed_err_str
          end
        when :mapping
          raise Puppet::DevError, "Debian interfaces mapping parsing not implemented."
        when :none
          raise Puppet::Error, malformed_err_str
        end
      end
    end
    iface_hash
  end

  # Generate an array of arrays
  def self.format_resources(providers)
    contents = []
    contents << header

    # Determine auto and hotplug interfaces and add them, if any
    [:auto, :"allow-auto", :"allow-hotplug"].each do |attr|
      interfaces = providers.select { |provider| provider.attributes[attr] }
      contents << "#{attr} #{interfaces.map {|i| i.name}.sort.join(" ")}" unless interfaces.empty?
    end

    # Build up iface blocks
    iface_interfaces = providers.select { |provider| provider.attributes[:iface] }
    iface_interfaces.each do |provider|
      attributes = provider.attributes.dup
      block = []
      if attributes[:iface]

        if [attributes[:iface][:method], attributes[:iface][:family]].any? {|val| val.nil?}
          raise Puppet::Error, "#{provider.name} does not have a method or family"
        end

        block << "iface #{provider.name} #{attributes[:iface][:family]} #{attributes[:iface][:method]}"
        block.concat(attributes[:iface][:options]) if attributes[:iface][:options]
      end
      contents << block.join("\n")
    end

    contents
  end
end

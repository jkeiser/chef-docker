module DockerCookbook
  require 'docker_service_base'
  class DockerService < DockerServiceBase
    use_automatic_resource_name

    # register with the resource resolution system
    provides :docker_service

    # installation type and service_manager
    property :install_method, %w(binary script package none auto), default: 'binary', desired_state: false
    property :service_manager, %w(execute sysvinit upstart systemd auto), default: 'auto', desired_state: false

    # docker_installation_binary
    property :checksum, String
    property :docker_bin, String
    property :source, String
    property :version, String

    # docker_installation_script
    property :repo, %w(main test experimental)
    property :script_url, String

    # docker_installation_package
    property :package_version, String
    property :version, String

    ################
    # Helper Methods
    ################
    def copy_properties_to(to, *properties)
      properties = self.class.properties.keys if properties.empty?
      properties.each do |p|
        # If the property is set on from, and exists on to, set
        # the property on to
        if to.class.properties.include?(p) && property_is_set?(p)
          to.send(p, self.send(p))
        end
      end
    end

    #########
    # Actions
    #########

    action :create do
      case install_method
      when 'auto'
        installation = docker_installation(name)
      when 'binary'
        installation = docker_installation_binary(name)
      when 'script'
        installation = docker_installation_script(name)
      when 'package'
        installation = docker_installation_package(name)
      when 'none'
        Chef::Log.info('Skipping Docker installation. Assuming it was handled previously.')
        return
      end

      installation.action = :create
      installation.notifies :restart, new_resource
      copy_properties_to(installation)
    end

    action :delete do
      docker_installation 'default' do
        action :delete
      end
    end

    action :start do
      property_def = proc do
      end

      case service_manager
      when 'auto'
        docker_service_manager(new_resource.instance, &property_def)
      when 'execute'
        docker_service_manager_execute(new_resource.instance, &property_def)
      when 'sysvinit'
        docker_service_manager_sysvinit(new_resource.instance, &property_def)
      when 'upstart'
        docker_service_manager_upstart(new_resource.instance, &property_def)
      when 'systemd'
        docker_service_manager_systemd(new_resource.instance, &property_def)
      end
    end

    action :stop do
      docker_service_manager 'default' do
        action :stop
      end
    end

    action :restart do
      docker_service_manager 'default' do
        action :restart
      end
    end
  end
end

# Declare a module for subresoures' providers to sit in (backcompat)
class Chef
  class Provider
    module DockerService
    end
  end
end

require 'hanami'
require 'hanami/environment'
require 'hanami/components'
require 'hanami/cli/command'
require 'hanami/cli/commands/project'
require 'hanami/cli/generator'
require 'concurrent'
require 'hanami/utils/files'
require 'erb'

module Hanami
  # Hanami CLI
  #
  # @since 1.1.0
  class CLI
    module Commands
      # Abstract command
      #
      # @since 1.1.0
      class Command < Hanami::CLI::Command
        # @since 1.1.0
        # @api private
        def self.inherited(component)
          super

          component.class_eval do
            @_requirements = Concurrent::Array.new
            extend ClassMethods
            prepend InstanceMethods
          end
        end

        # Class level interface
        #
        # @since 1.1.0
        module ClassMethods
          # Requires an internal Hanami component
          #
          # @param names [Array<String>] the name of one or more components
          #
          # @since 1.1.0
          #
          # @example
          #   require "hanami/cli/commands"
          #
          #   module HanamiDatabaseHelpers
          #     class TruncateTables < Hanami::CLI::Commands::Command
          #       requires "model.configuration"
          #
          #       def call(*)
          #         url = requirements["model.configuration"].url
          #         # ...
          #       end
          #     end
          #   end
          #
          #   Hanami::CLI.register "db truncate", HanamiDatabaseHelpers::TruncateTables
          def requires(*names)
            requirements.concat(names)
          end

          # @since 1.1.0
          # @api private
          def requirements
            @_requirements
          end
        end

        # @since 1.1.0
        # @api private
        module InstanceMethods
          # @since 1.1.0
          # @api private
          def call(**options)
            if self.class.requirements.any?
              environment = Hanami::Environment.new(options)
              environment.require_project_environment

              requirements.resolved('environment', environment)
              requirements.resolve(self.class.requirements)

              options = environment.to_options.merge(options)
            end

            super(options)
          rescue StandardError => e
            warn e.message
            warn e.backtrace.join("\n\t")
            exit(1)
          end
        end

        # @since 1.1.0
        # @api private
        def initialize(command_name:, out: $stdout, files: Utils::Files, generator: nil)
          super(command_name: command_name)

          @out       = out
          @files     = files
          @generator = generator || default_generator
        end

        private

        # @since x.x.x
        # @api private
        def default_generator
          Generator.new(out: out, files: files, root_dir: templates_root_dir)
        end

        # @since x.x.x
        # @api private
        def templates_root_dir
          Pathname.new(File.join(__dir__, command_name.split(" ")))
        end

        # @since 1.1.0
        # @api private
        attr_reader :out

        # @since 1.1.0
        # @api private
        attr_reader :files

        # @since x.x.x
        # @api private
        attr_reader :generator

        # @since 1.1.0
        # @api private
        def project
          Project
        end

        # @since 1.1.0
        # @api private
        def requirements
          Hanami::Components
        end
      end
    end
  end
end

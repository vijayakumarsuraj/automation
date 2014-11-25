#
# Suraj Vijayakumar
# 25 Oct 2013
#

require 'svn/svn_info'
require 'svn/svn_log'

module Automation::Svn

  # Raised when an error is encountered while running an SVN command.
  class Error < Automation::Error
  end

  class Repo

    # Creates a new SVN repo at the specified location.
    #
    # @param [String] repo_path
    def initialize(repo_path)
      @repo = repo_path
    end

    # Returns the content of the specified file.
    #
    # @param [String] file the file whose content is required (relative to the repo).
    # @param [Integer] rev the required revision number (default is 'HEAD').
    # @param [Hash] options optional arguments
    #   username: if specified adds the --username option.
    #   password: if specified adds the --password option (plain-text).
    # @return [String] the content of the specified file.
    def get_content(file, rev = 'HEAD', options = {})
      args = standard_args(options)
      args.push('--revision', rev)
      args.push("#{@repo}/#{file}")

      svn('cat', args)
    end

    # Returns info about this repository.
    #
    # @param [Hash] options optional arguments
    #   username: if specified adds the --username option.
    #   password: if specified adds the --password option (plain-text).
    # @return [Svn::Info]
    def get_info(options = {})
      args = standard_args(options)
      args.push('--xml')
      args.push(@repo)

      info_xml = svn('info', args)
      Svn::Info.parse(info_xml)
    end

    # Returns the SVN logs for this repo.
    #
    # @param [Integer] rev_from the start revision ('BASE' allowed).
    # @param [Integer] rev_to the end revision ('HEAD' allowed).
    # @param [Hash] options optional arguments
    #   username: if specified adds the --username option.
    #   password: if specified adds the --password option (plain-text).
    # @return [Array<Svn::Log>]
    def get_log(rev_from, rev_to, options = {})
      args = standard_args(options)
      args.push('--revision', "#{rev_from}:#{rev_to}")
      args.push('--verbose', '--xml')
      args.push(@repo)

      log_xml = run('log', args)
      Svn::Log.parse(log_xml)
    end

    private

    # Runs an SVN command. Uses the SVN executable on the local machine.
    # Raises an Error if the command did not execute successfully.
    #
    # @param [String] command the SVN command to execute.
    # @param [Array] args arguments to pass to the SVN command.
    # @return [String] the value returned by the command.
    def svn(command, args, options = {})
      svn_executable = @config_manager['tool.svn.executable']
      message, status = popen_capture(svn_executable, *([command] + args))
      raise Error.new("svn '#{command}' - #{status}\n#{message}") if status != 0

      message
    end

    # Returns an array containing some standard SVN arguments.
    #
    # @param [Hash] options optional arguments
    #   username: if specified adds the --username option.
    #   password: if specified adds the --password option (plain-text).
    def standard_args(options = {})
      args = []
      args.push('--username', options[:username]) if options.has_key?(:username)
      args.push('--password', options[:password]) if options.has_key?(:password)
      args.push('--no-auth-cache', '--non-interactive')

      args
    end

  end

end

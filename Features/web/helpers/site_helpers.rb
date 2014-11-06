#
# Suraj Vijayakumar
# 13 Feb 2013
#

module Automation

  module SiteHelpers

    # Get the text to be displayed for a particular change.
    #
    # @param [Automation::Change] change the change.
    def change_text(change)
      case (change)
        when Automation::Change::TestAdded
          'added'
        when Automation::Change::TestRemoved
          'removed'
        when Automation::Change::TestStartedFailing
          'started failing'
        when Automation::Change::TestStartedPassing
          'started passing'
        when Automation::Change::TestChangedFailure
          'new failure'
        else
          'unknown'
      end
    end

    # Get a summary string for the date times of the specified entity.
    #
    # @param [Automation::ResultsDatabase::TestResult, Automation::ResultsDatabase::RunResult] entity
    def entity_date_time_summary(entity, overrides = {})
      defaults = {time_format: :time, include_end_time: true, include_duration: true}
      overrides = defaults.merge(overrides)
      #
      time_format = overrides[:time_format]
      include_end_time = overrides[:include_end_time]
      include_duration = overrides[:include_duration]
      #
      start_date_time = entity.start_date_time
      end_date_time = entity.end_date_time
      # Format the start date time.
      formatted_string = date_time_format(start_date_time, time_format)
      # Format the end date time, if it is required.
      if include_end_time
        end_date_time_str = end_date_time.nil? ? '???' : date_time_format(end_date_time, time_format)
        formatted_string << " - #{end_date_time_str}"
      end
      # Format the duration, if it is required.
      if include_duration
        end_date_time = Time.now if end_date_time.nil?
        duration_str = date_time_duration(start_date_time, end_date_time)
        formatted_string << " (#{duration_str})"
      end
      # Return the complete string.
      formatted_string
    end

    # Get the result of the specified entity
    #
    # @param [Automation::ResultsDatabase::RunResult, Automation::ResultsDatabase::TestResult] entity
    def entity_result(entity)
      weight = entity.result
      weight.nil? ? Automation::Result::Unknown : weight
    end

    # Get the status of the specified entity
    #
    # @param [Automation::ResultsDatabase::RunResult, Automation::ResultsDatabase::TestResult] entity
    def entity_status(entity)
      value = entity.status
      value.nil? ? Automation::Status::Complete : value
    end

    # Returns the types of supported flash messages.
    #
    # @return [Array<Symbol>]
    def flash_messages
      [:fail, :warn, :pass]
    end

    # Returns a JQuery statement for setting up a hover hint for the specified source element.
    def hover_hint(source_id, hint_text)
      "$('##{source_id}').hover(function() { hintPopupHoverIn(this, '#{hint_text}'); }, function() { hintPopupHoverOut(this); });"
    end

    # Creates a link to the specified resource.
    #
    # @param [Array] resources the fully qualified path to the resource.
    def link(*resources)
      "#{@link_prefix}#{resources.join('/')}"
    end

    # Pluralize the specified text.
    #
    # @param [Integer] count the count.
    # @param [String] pattern the suffix pattern.
    # @param [Array] args additional substitution arguments.
    # @return [String] the plural version of the string (unless count was 1, in which return the string as is).
    def pluralize(count, pattern, *args)
      args = args.map { |arg| arg.pluralize(count) }
      pattern % args
    end

    # Get the text to be displayed for a particular result.
    #
    # @param [Automation::Result] result the result.
    def result_text(result)
      case (result)
        when Automation::Result::Pass
          return 'Passed'
        when Automation::Result::Warn
          return 'Warning'
        when Automation::Result::Fail
          return 'Failed'
        when Automation::Result::Exception
          return 'Exception'
        when Automation::Result::Ignored
          return 'Ignored'
        when Automation::Result::TimedOut
          return 'Timed out'
        else
          return 'Unknown'
      end
    end

    # Get the name of the style given a result.
    #
    # @param [Automation::Result] result the result.
    def result_style(result)
      case (result)
        when Automation::Result::Pass
          return 'pass'
        when Automation::Result::Warn
          return 'warn'
        when Automation::Result::Fail
          return 'fail'
        when Automation::Result::Exception, Automation::Result::TimedOut, Automation::Result::Unknown
          return 'exception'
        when Automation::Result::Ignored
          return 'ignored'
        else
          return ''
      end
    end

    # Get an application specific view configuration value.
    #
    # @param [String] application
    # @param [String] key
    # @param [Object] default
    # @return [String]
    def scoped_config(application, key, default = nil)
      app_key = "web.#{application}.view.#{key}"
      default_key = "web.view.#{key}"
      @config_manager.has_property?(app_key) ? @config_manager[app_key] : @config_manager[default_key, default: nil]
    end

    # Special partial implementation that looks for application specific partials also.
    #
    # @param [String] file the partial's name.
    # @param [String] application the current application
    # @param [Hash] options hash to pass to the 'partial' method.
    def scoped_partial(file, application, options = {})
      app_partial = "partials/#{application}.#{file}"
      default_partial = "partials/#{file}"
      (!application.nil? && view_exist?(app_partial)) ? partial(app_partial, options) : partial(default_partial, options)
    end

    # Returns an application specific setting.
    #
    # @param [String] setting
    # @param [String] application
    # @param [Object] default
    # @return [Object]
    def scoped_setting(setting, application, default = nil)
      # Return the default value if there is no application specific setting.
      key = "#{application}.#{setting}"
      return session[key] if session.has_key?(key)
      return @defaults[application][setting] if @defaults.has_key?(application) && @defaults[application].has_key?(setting)
      default
    end

    # Get the text to be displayed for a particular status.
    #
    # @param [Automation::Status] status the result.
    def status_text(status)
      case (status)
        when Automation::Status::Running
          return 'Running'
        when Automation::Status::Analysing
          return 'Analysing results'
        when Automation::Status::Complete
          return 'Complete'
        else
          return 'Unknown'
      end
    end

    # Converts the specified object to a boolean.
    # If the string is '1', 'true', 'yes' or 'y' returns true.
    # Anything else, return false.
    #
    # @param [Object] object the object to convert.
    # @param [Boolean] default
    # @return [Boolean] the boolean.
    def to_boolean(object, default = false)
      if object.kind_of?(TrueClass) || object.kind_of?(FalseClass)
        object
      elsif object.kind_of?(String)
        %w(yes y true 1).include?(object.downcase)
      else
        default
      end
    end

    # Check to see if the specified view exists.
    #
    # @param [String] view the logical name of the view.
    # @param [String] ext the extension for the view file.
    def view_exist?(view, ext = 'haml')
      view_root = settings.views
      view_path = File.join(view_root, "#{view}.#{ext}")
      File.exist?(view_path)
    end

  end

end
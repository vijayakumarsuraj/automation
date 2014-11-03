#
# Suraj Vijayakumar
# 17 May 2013
#

module Automation

  module DiffHelpers

    # Generates the diff of the specified strings and returns an HTML report.
    # Internally, generates temporary files with the content and calls the 'generate_file_diff' method.
    #
    # @param [String] left the original content (expected)
    # @param [String] right the new content (actual).
    # @param [Hash] overrides optional overrides.
    #   title_left: the title of the expected content (default is 'Expected').
    #   title_right: the title of the actual content (default is 'Actual').
    #   stylesheet: the stylesheet to be used (default is /styles/compare_it.css).
    # @return [String] the diff content.
    def generate_content_diff(left, right, overrides = {})
      # Create the temporary files...
      temp_left_file = Tempfile.new('left')
      temp_right_file = Tempfile.new('right')
      # ... and put them in binary mode...
      temp_left_file.binmode
      temp_right_file.binmode
      # ... and write to them.
      temp_left_file.write(left)
      temp_right_file.write(right)
      # Close them so that the diff library can access them.
      temp_left_file.close
      temp_right_file.close

      generate_file_diff(temp_left_file.path, temp_right_file.path, overrides)
    ensure
      # Deletes the files once we're done.
      temp_left_file.unlink
      temp_right_file.unlink
    end

    # Generates the diff of the specified files and returns an HTML report.
    #
    # @param [String] left the original file (expected)
    # @param [String] right the new file (actual).
    # @param [Hash] overrides optional overrides.
    #   title_left: the title of the expected file (default is 'Expected').
    #   title_right: the title of the actual file (default is 'Actual').
    def generate_file_diff(left, right, overrides = {})
      defaults = {title_left: 'Expected', title_right: 'Actual', stylesheet: link('styles/compare_it.css')}
      overrides = defaults.merge(overrides)
      # Temporary file for the HTML report - it is deleted after we're done.
      temp_diff_file = Tempfile.new('diff')
      temp_diff_file.close
      # The Windows file paths.
      left_file = Converter.to_windows_path(left)
      right_file = Converter.to_windows_path(right)
      diff_file = Converter.to_windows_path(temp_diff_file.path)
      # Arguments
      # /min - Minimised mode.
      # /G: - Generate report, N - Line numbers, S - Statistics, X - External CSS, 0 - Context lines.
      executable = @config_manager['tool.compare_it.executable']
      args = [left_file, "/=#{overrides[:title_left]}", right_file, "/=#{overrides[:title_right]}", '/min', '/G:NSX0', diff_file]
      FileUtils.cd(Dir.tmpdir) { system(executable, *args) }
      # The diff content.
      diff_html = File.readlines(temp_diff_file.path)
      diff_html[0] = '<!DOCTYPE html>' + "\n"
      diff_html[6] = '<link href="' + overrides[:stylesheet] + '" rel="stylesheet" type="text/css" />' + "\n"
      # Delete the temporary file.
      temp_diff_file.unlink
      # Return the diff content.
      diff_html.join
    end

  end

end

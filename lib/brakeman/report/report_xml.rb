require 'builder'

class Brakeman::Report::XML < Brakeman::Report::Base
  def generate_report
    x = Builder::XmlMarkup.new(:indent => 2)
    x.instruct!

    warnings = convert_to_hashes all_warnings, :warning

    errors = tracker.errors.map{|e| { :error => {:error_message => e[:error], :location => e[:backtrace][0]} }}

    ignored = convert_to_hashes ignored_warnings, :ignored_warning

    checks_performed = checks.checks_run.map{|c| {:check => c.to_s}}

    scanInfo = {
      :app_path => File.expand_path(tracker.app_path),
      :ruby_version => RUBY_VERSION,
      :rails_version => rails_version,
      :brakeman_version => Brakeman::Version,
      :report_generation_time => Time.now.to_s,
      :start_time => tracker.start_time.to_s,
      :end_time => tracker.end_time.to_s,
      :duration => tracker.duration,
      :checks => checks_performed
    }

    reportInfo = {
      :scan_info => scanInfo,
      :warnings => warnings,
      :ignored_warnings => ignored,
      :errors => errors
    }

    output_xml x, :report_info, reportInfo

  end

  def convert_to_hashes warnings, typ
    warnings.map do |w|
      hash = w.to_hash
      hash[:file] = warning_file w
      # hash[:location] = hash[:location].flatten.join(',') unless hash[:location].nil?
      hash[:location] = hash[:location].map{|hash, value| {hash => value.to_s}} unless hash[:location].nil?
      item = {typ => hash}
      item
    end.sort_by { |w| "#{w[:fingerprint]}#{w[:line]}" }
  end

  def output_xml xml, label, data
    xml.tag!(label) do
      data.each do |hash, value|
        if value.is_a? Hash
          output_xml xml, hash, value
        elsif value.is_a? Array
          xml.tag!(hash) do
            value.each do |v|
              print_hash xml, v
            end
          end
        else
          xml.tag!(hash, value)
        end
      end
    end
  end

  def print_hash xml, data
    data.each do |hash, value|
      if value.is_a? Hash
        output_xml xml, hash, value
      else
        xml.tag!(hash, value)
      end
    end
  end

end

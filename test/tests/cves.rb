require 'brakeman/rescanner'

class CVETests < Test::Unit::TestCase
  include BrakemanTester::RescanTestHelper
  include BrakemanTester::FindWarning

  def report
    @rescanner.tracker.report.to_hash
  end

  def assert_version version, gem = :rails
    if gem == :rails
      assert_equal version, @rescanner.tracker.config.rails_version
    else
      assert_equal version, @rescanner.tracker.config.gem_version(gem)
    end
  end

  def test_CVE_2015_3226_4_1_1
    before_rescan_of "Gemfile", "rails4" do
      replace "Gemfile", "4.0.0", "4.1.1"
    end

    assert_version "4.1.1"
    assert_warning :type => :warning,
      :warning_code => 87,
      :fingerprint => "6c2281400c467a0100bcedeb122bc2cb024d09e538e18f4c7328c3569fff6754",
      :warning_type => "Cross Site Scripting",
      :line => 4,
      :message => /^Rails\ 4\.1\.1\ does\ not\ encode\ JSON\ keys\ \(C/,
      :confidence => 0,
      :relative_path => "Gemfile",
      :user_input => nil
  end

  def test_CVE_2015_3226_4_2_1
    before_rescan_of "Gemfile", "rails4" do
      replace "Gemfile", "4.0.0", "4.2.1"
    end

    assert_version "4.2.1"
    assert_warning :type => :warning,
      :warning_code => 87,
      :fingerprint => "6c2281400c467a0100bcedeb122bc2cb024d09e538e18f4c7328c3569fff6754",
      :warning_type => "Cross Site Scripting",
      :line => 4,
      :message => /^Rails\ 4\.2\.1\ does\ not\ encode\ JSON\ keys\ \(C/,
      :confidence => 0,
      :relative_path => "Gemfile",
      :user_input => nil
  end

  def test_CVE_2015_3226_workaround
    initializer = "config/initializers/json.rb"
    before_rescan_of ["Gemfile", initializer], "rails4" do
      replace "Gemfile", "4.0.0", "4.2.1"

      write_file initializer, <<-RUBY
      module ActiveSupport
        module JSON
          module Encoding
            private
            class EscapedString
              def to_s
                self
              end
            end
          end
        end
      end
      RUBY
    end

    assert_version "4.2.1"
    assert_no_warning :type => :warning,
      :warning_code => 87,
      :fingerprint => "6c2281400c467a0100bcedeb122bc2cb024d09e538e18f4c7328c3569fff6754",
      :warning_type => "Cross Site Scripting",
      :line => 4,
      :message => /^Rails\ 4\.2\.1\ does\ not\ encode\ JSON\ keys\ \(C/,
      :confidence => 0,
      :relative_path => "Gemfile",
      :user_input => nil
  end

  def test_CVE_2015_3227_4_2_1
    before_rescan_of "Gemfile", "rails4" do
      replace "Gemfile", "4.0.0", "4.2.1"
    end

    assert_version "4.2.1"
    assert_warning :type => :warning,
      :warning_code => 88,
      :fingerprint => "6ad4464dbb2a999591c7be8346dc137c3372b280f4a8b0c024fef91dfebeeb83",
      :warning_type => "Denial of Service",
      :line => 4,
      :message => /^Rails\ 4\.2\.1\ is\ vulnerable\ to\ denial\ of\ s/,
      :confidence => 1,
      :relative_path => "Gemfile",
      :user_input => nil
  end

  def test_CVE_2015_3227_4_1_11
    before_rescan_of "Gemfile", "rails4" do
      replace "Gemfile", "4.0.0", "4.1.11"
    end

    assert_version "4.1.11"
    assert_no_warning :type => :warning,
      :warning_code => 88,
      :warning_type => "Denial of Service",
      :line => 4,
      :confidence => 1,
      :relative_path => "Gemfile",
      :user_input => nil
  end

  def test_CVE_2015_3227_workaround
    initializer = "config/initializers/xml.rb"
    before_rescan_of ["Gemfile", initializer], "rails4" do
      replace "Gemfile", "4.0.0", "4.1.11"
      write_file initializer, "ActiveSupport::XmlMini.backend = 'Nokogiri'"
    end

    assert_version "4.1.11"
    assert_no_warning :type => :warning,
      :warning_code => 88,
      :warning_type => "Denial of Service",
      :line => 4,
      :confidence => 1,
      :relative_path => "Gemfile",
      :user_input => nil
  end

  def test_CVE_2015_3227_3_2_22
    before_rescan_of "Gemfile.lock", "rails3.2" do
      replace "Gemfile.lock", "rails (3.2.9.rc2)", "rails (3.2.22)"
    end

    assert_version "3.2.22"
    assert_no_warning :type => :warning,
      :warning_code => 88,
      :warning_type => "Denial of Service"
  end

  def test_railties_version
    before_rescan_of "Gemfile", "rails4" do
      replace "Gemfile", "rails", "railties"
    end

    assert_version "4.0.0"
  end

  def test_new_bundler_file_names
    before_rescan_of ["Gemfile", "Gemfile.lock"] do
      rename "Gemfile", "gems.rb"
      rename "Gemfile.lock", "gems.locked"
    end

    assert_changes
    assert_new 0
    assert_fixed 0
    assert_version "3.2.9.rc2"
  end

  def test_ignored_secrets_yml
    before_rescan_of [".gitignore", "config/secrets.yml"], "rails4" do
      append ".gitignore", "\nconfig/secrets.yml"
    end

    assert_new 0
    assert_fixed 1
  end
end

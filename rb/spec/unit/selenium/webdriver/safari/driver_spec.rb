# frozen_string_literal: true

# Licensed to the Software Freedom Conservancy (SFC) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The SFC licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require File.expand_path('../spec_helper', __dir__)

module Selenium
  module WebDriver
    module Safari
      describe Driver do
        let(:service) do
          instance_double(Service, launch: service_manager, executable_path: nil, 'executable_path=': nil,
                                   class: Safari::Service)
        end
        let(:service_manager) { instance_double(ServiceManager, uri: 'http://example.com') }
        let(:valid_response) do
          {status: 200,
           body: {value: {sessionId: 0, capabilities: {browserName: 'safari'}}}.to_json,
           headers: {content_type: 'application/json'}}
        end

        def expect_request(body: nil, endpoint: nil)
          body = (body || {capabilities: {alwaysMatch: {browserName: 'safari'}}}).to_json
          endpoint ||= "#{service_manager.uri}/session"
          stub_request(:post, endpoint).with(body: body).to_return(valid_response)
        end

        before do
          allow(Service).to receive_messages(new: service)
        end

        it 'uses DriverFinder when provided Service without path' do
          expect_request
          allow(DriverFinder).to receive(:path)
          options = Options.new

          described_class.new(service: service, options: options)
          expect(DriverFinder).to have_received(:path).with(options, service.class)
        end

        it 'does not use DriverFinder when provided Service with path' do
          expect_request
          allow(service).to receive(:executable_path).and_return('path')
          allow(DriverFinder).to receive(:path)

          described_class.new(service: service)
          expect(DriverFinder).not_to have_received(:path)
        end

        it 'does not require any parameters' do
          allow(SeleniumManager).to receive(:driver_path).and_return('/path/to/safaridriver')
          allow(Platform).to receive(:assert_file)
          allow(Platform).to receive(:assert_executable)
          expect_request

          expect { described_class.new }.not_to raise_exception
        end

        it 'accepts provided Options as sole parameter' do
          allow(SeleniumManager).to receive(:driver_path).and_return('/path/to/safaridriver')
          allow(Platform).to receive(:assert_file)
          allow(Platform).to receive(:assert_executable)
          opts = {automatic_inspection: true}
          expect_request(body: {capabilities: {alwaysMatch: {browserName: 'safari',
                                                             'safari:automaticInspection': true}}})

          expect { described_class.new(options: Options.new(**opts)) }.not_to raise_exception
        end

        it 'does not accept Options of the wrong class' do
          expect {
            described_class.new(options: Options.chrome)
          }.to raise_exception(ArgumentError, ':options must be an instance of Selenium::WebDriver::Safari::Options')
        end

        it 'does not allow both Options and Capabilities' do
          msg = "Don't use both :options and :capabilities when initializing Selenium::WebDriver::Safari::Driver, " \
                'prefer :options'
          expect {
            described_class.new(options: Options.new, capabilities: Remote::Capabilities.new(browser_name: 'safari'))
          }.to raise_exception(ArgumentError, msg)
        end

        context 'with :capabilities' do
          before { allow(DriverFinder).to receive(:path) }

          it 'accepts value as a Symbol' do
            expect_request(body: {capabilities: {alwaysMatch: {browserName: 'safari'}}})
            expect { described_class.new(capabilities: :safari) }.to have_deprecated(:capabilities)
          end

          it 'accepts constructed Capabilities with Snake Case as Symbols' do
            capabilities = Remote::Capabilities.new(browser_name: 'safari', invalid: 'foobar')
            expect_request(body: {capabilities: {alwaysMatch: {browserName: 'safari', invalid: 'foobar'}}})

            expect { described_class.new(capabilities: capabilities) }.to have_deprecated(:capabilities)
          end

          it 'accepts constructed Capabilities with Camel Case as Symbols' do
            capabilities = Remote::Capabilities.new(browserName: 'safari', invalid: 'foobar')
            expect_request(body: {capabilities: {alwaysMatch: {browserName: 'safari', invalid: 'foobar'}}})

            expect { described_class.new(capabilities: capabilities) }.to have_deprecated(:capabilities)
          end

          it 'accepts constructed Capabilities with Camel Case as Strings' do
            capabilities = Remote::Capabilities.new('browserName' => 'safari', 'invalid' => 'foobar')
            expect_request(body: {capabilities: {alwaysMatch: {browserName: 'safari', invalid: 'foobar'}}})

            expect { described_class.new(capabilities: capabilities) }.to have_deprecated(:capabilities)
          end

          context 'when value is an Array' do
            let(:as_json_object) do
              Class.new do
                def as_json(*)
                  {'company:key': 'value'}
                end
              end
            end

            it 'with Options instance' do
              browser_opts = {automatic_inspection: true}
              expect_request(body: {capabilities: {alwaysMatch: {browserName: 'safari',
                                                                 'safari:automaticInspection': true}}})

              expect {
                described_class.new(capabilities: [Options.new(**browser_opts)])
              }.to have_deprecated(:capabilities)
            end

            it 'with Capabilities instance' do
              capabilities = Remote::Capabilities.new(browser_name: 'safari', invalid: 'foobar')
              expect_request(body: {capabilities: {alwaysMatch: {browserName: 'safari', invalid: 'foobar'}}})

              expect { described_class.new(capabilities: [capabilities]) }.to have_deprecated(:capabilities)
            end

            it 'with Options instance and an instance of a custom object responding to #as_json' do
              expect_request(body: {capabilities: {alwaysMatch: {browserName: 'safari',
                                                                 'company:key': 'value'}}})

              expect {
                described_class.new(capabilities: [Options.new, as_json_object.new])
              }.to have_deprecated(:capabilities)
            end

            it 'with Options instance, Capabilities instance and instance of a custom object responding to #as_json' do
              capabilities = Remote::Capabilities.new(browser_name: 'safari', invalid: 'foobar')
              options = Options.new(automatic_inspection: true)
              expect_request(body: {capabilities: {alwaysMatch: {browserName: 'safari',
                                                                 invalid: 'foobar',
                                                                 'safari:automaticInspection': true,
                                                                 'company:key': 'value'}}})

              expect {
                described_class.new(capabilities: [capabilities, options, as_json_object.new])
              }.to have_deprecated(:capabilities)
            end
          end
        end
      end
    end # Safari
  end # WebDriver
end # Selenium

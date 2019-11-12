require 'juniper_telemetry_lib.rb'
require 'protobuf'
require 'telemetry_top.pb.rb'
require 'port.pb.rb'
require 'lsp_stats.pb.rb'
require 'logical_port.pb.rb'
require 'firewall.pb.rb'
require 'cpu_memory_utilization.pb.rb'

module Fluent
  class TextParser
    class JuniperJtiParser < Parser

      Plugin.register_parser("juniper_jti", self)

      config_param :output_format, :string, :default => 'structured'

      # This method is called after config_params have read configuration parameters
      def configure(conf)
        super

        ## Check if "output_format" has a valid value
        unless  @output_format.to_s == "structured" ||
                @output_format.to_s == "flat" ||
                @output_format.to_s == "statsd"

          raise ConfigError, "output_format value '#{@output_format}' is not valid. Must be : structured, flat or statsd"
        end
      end

      def parse(text)

        ## Decode GBP packet
        jti_msg =  TelemetryStream.decode(text)

        resource = ""

        ## Extract device name & Timestamp
        device_name = jti_msg.system_id
        component_id =jti_msg.component_id
        gpb_time = epoc_to_sec(jti_msg.timestamp)

        ## Extract sensor
        begin
          jnpr_sensor = jti_msg.enterprise.juniperNetworks
          datas_sensors = JSON.parse(jnpr_sensor.to_json)
          $log.debug  "Extract sensor data from #{device_name} with output #{output_format}"
        rescue => e
          $log.warn   "Unable to extract sensor data sensor from jti_msg.enterprise.juniperNetworks, Error during processing: #{$!}"
          $log.debug  "Unable to extract sensor data sensor from jti_msg.enterprise.juniperNetworks, Data Dump : " + jti_msg.inspect.to_s
          return
        end

        ## Go over each Sensor
        datas_sensors.each do |sensor, s_data|

          ##############################################################
          ### Support for resource /junos/system/linecard/firewall/   ##
          ##############################################################
          #{"message":"Unable to parse jnpr_firewall_ext sensor, Data Dump : {\"jnpr_firewall_ext\"=>
          #{\"firewall_stats\"=>[{\"filter_name\"=>\"__default_bpdu_filter__\", \"timestamp\"=>1465467390, \"memory_usage\"=>[{\"name\"=>\"HEAP\", \"allocated\"=>2440}]},
          #{\"filter_name\"=>\"test\", \"timestamp\"=>1465467390, \"memory_usage\"=>[{\"name\"=>\"HEAP\", \"allocated\"=>1688}],
          #\"counter_stats\"=>[{\"name\"=>\"cnt1\", \"packets\"=>79, \"bytes\"=>6320}]},
          #{\"filter_name\"=>\"__default_arp_policer__\", \"timestamp\"=>1464456904, \"memory_usage\"=>[{\"name\"=>\"HEAP\", \"allocated\"=>1600}]}]}}"}

          if sensor == "jnpr_firewall_ext"

            resource = "/junos/system/linecard/firewall/"
            $log.debug  "Will extract info for Sensor: #{sensor} / Resource #{resource}"

            datas_sensors[sensor]['firewall_stats'].each do |datas|

              # Save all info extracted on a list
              sensor_data = []

              begin
                ## Extract interface name and clean up
                sensor_data.push({ 'device' => device_name  })
                sensor_data.push({ 'component_id' => component_id  })
                sensor_data.push({ 'filter_name' => datas['filter_name']  })
                sensor_data.push({ 'filter_timestamp' => datas['timestamp']  })

                ## Clean up Current object
                datas.delete("filter_name")
                datas.delete("timestamp")

                if datas.key?('counter_stats')
                  datas['counter_stats'].each do |counters|
                    sensor_data.push({ 'filter_counter_name' => counters['name']  })
                    counters.delete("name")
                    counters.each do |type, value|
                      sensor_data.push({ type =>  value  })
                      record = build_record(output_format, sensor_data)
                      yield gpb_time, record
                    end
                  end
                end

              rescue => e
                $log.warn   "Unable to parse " + sensor + " sensor, Error during processing: #{$!}"
                $log.debug  "Unable to parse " + sensor + " sensor, Data Dump : " + datas_sensors.inspect.to_s
              end
            end

          # Ignore any other sensor
          else
            $log.debug  "Unsupported sensor : " + sensor
            # puts datas_sensors[sensor].inspect.to_s
          end
        end
      end
    end
  end
end

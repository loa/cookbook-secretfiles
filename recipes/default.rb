#
# Cookbook Name:: secretfiles
# Recipe:: default
#
# Author:: Carl Loa Odin (<carlodin@gmail.com>)
#
# Copyright 2014 Carl Loa Odin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

node['secretfiles'].each do |name, settings|
  secret_file = settings['secret-file']
  if not File.exists? secret_file
    log "#####################################################"
    log "Secretfiles: Skipping data_bag #{settings['data_bag']}"
    log "Secret key file do not exist, #{secret_file}."
    log "#####################################################"

    next
  end

  secret_key = Chef::EncryptedDataBagItem.load_secret(secret_file)

  settings['items'].each do |item_name|
    log "Secretfiles: #{settings['data_bag']}:#{item_name}"

    item = Chef::EncryptedDataBagItem.load(settings['data_bag'], item_name, secret_key)

    # copy notify settings to local array
    notify_settings = Array.new
    notify_settings = settings['notifies'].to_a if settings.has_key?('notifies')
    
    # :delayed is default timer
    notify_settings[2] = :delayed if notify_settings.length < 3

    item['secretfiles'].each do |file_info|
      # Create enclosing dir if it doesn't exist
      directory File.dirname(file_info['path']) do
        recursive true
      end

      file "#{file_info['path']}" do
        content Base64.decode64(file_info['content'])
        owner file_info['owner'] if file_info.has_key?('owner')
        group file_info['group'] if file_info.has_key?('group')
        mode file_info['mode'] if file_info.has_key?('mode')
        sensitive true
        notifies notify_settings[0].to_sym,
                 notify_settings[1],
                 notify_settings[2].to_sym if not notify_settings.empty?
      end
    end
  end
end

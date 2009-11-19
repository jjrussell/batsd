# = Utilities : Amazon SimpleDB BatchPutAttributes
# Extends the right_aws gem providing support for 
# Amazon SimpleDB BatchPutAttributes operation.
#
# The right_aws gem provides basic functionality to interact with Amazon
# SimpleDB, but it doesn't support BatchPutAttributes (as of version 1.10.0),
# severely limiting the upload speed that can be achieved when storing data
# into SimpleDB.
# This module adds basic support for the missing functionality.
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2009 - bayes-swarm project.
# Licensed under the GNU General Public License v2.

require 'right_aws'

module RightAws
  class SdbInterface
    
    # Add/Replace item attributes in Batch mode.
    # By using Amazon SDB BatchPutAttributes rather than PutAttributes this
    # method achieves a 15x-20x speed improvement when storing big quantities
    # of attributes.
    #
    # Params:
    #  domain_name = DomainName
    #  items = {
    #    'itemname' => {
    #      'attributeA' => [valueA1,..., valueAN],
    #      ...
    #      'attributeZ' => [valueZ1,..., valueZN]
    #    }
    #  }
    #  replace = :replace | any other value to skip replacement
    #
    # Returns a hash: { :box_usage, :request_id } on success or an exception on error. 
    #
    # see: http://docs.amazonwebservices.com/AmazonSimpleDB/2007-11-07/DeveloperGuide/SDB_API_BatchPutAttributes.html 
    def batch_put_attributes(domain_name, items, replace = false)
      params = { 'DomainName' => domain_name }
      item_count = 0
      items.each_pair do |item_name, attributes|
        params["Item.#{item_count}.ItemName"] = item_name
        pack_attributes(attributes, replace).each_pair do |attr_key, attr_value|
          params["Item.#{item_count}.#{attr_key}"] = attr_value
        end
        item_count += 1
      end
      link = generate_request("BatchPutAttributes", params)
      request_info( link, QSdbSimpleParser.new )
    rescue Exception
      on_exception
    end
  end
end

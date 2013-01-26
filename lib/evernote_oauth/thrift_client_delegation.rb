module EvernoteOAuth

  module ThriftClientDelegation
    def method_missing(name, *args, &block)
      case name.to_s
      when 'checkVersion'
        parameters = [[:req, :clientName], [:req, :edamVersionMajor], [:req, :edamVersionMinor]]
      when /^(?:create|update|share)(.+)$/
        parameters = [[:req, :authenticationToken], [:req, $1.downcase.to_sym]]
      else
        parameters = [[:req, :authenticationToken]]
      end
      if parameters.size != args.size && idx_token = parameters.index{|e| e.last == :authenticationToken}
        new_args = args.dup.insert(idx_token, @token)
        begin
          result = @client.send(name, *new_args, &block)
        rescue ArgumentError => e
          puts e.inspect
          result = @client.send(name, *args, &block)
        end
      else
        result = @client.send(name, *args, &block)
      end

      attr_name = underscore(self.class.name.split('::').last).to_sym
      attr_value = self
      [result].flatten.each{|r|
        begin
          c = class << r; self; end
          c.send(:define_method, :attr_name) {attr_value}
        rescue TypeError # Fixnum/TrueClass/FalseClass/NilClass
          next
        end
      }
      result
    end

    private
    def underscore(word)
      word.to_s.gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end
  end

end

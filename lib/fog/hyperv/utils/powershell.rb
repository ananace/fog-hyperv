# frozen_string_literal: true

module Fog::Hyperv::Utils::Powershell
  # Build a Powershell option map from a set of keyword arguments
  def self.build_optmap(_optmap_name: 'FogArgs', _ps_version: 5, _from_json: true, **_options)
    ps_opts = Fog::Hyperv.camelize(_options)
    if _from_json
      if _ps_version >= 6
        ["$#{_optmap_name} = ConvertFrom-Json -AsHashtable '#{Fog::JSON.encode ps_opts}'"]
      else
        [
          [
            "$FogJsonObject = '#{Fog::JSON.encode ps_opts}'",
            '$FogJsonParameters = ConvertFrom-Json -InputObject $FogJsonObject',
            "$#{_optmap_name} = @{}",
            "$FogJsonParameters.psobject.properties | Foreach { $#{_optmap_name}[$_.Name] = $_.Value }"
          ].join('; ')
        ]
      end
    else
      args = ps_opts.map do |k, v|
        "'#{k}'=#{Fog::Hyperv.shell_quote(v, always: true)}"
      end

      ["$#{_optmap_name} = @{#{args.join ';'}}"]
    end
  end

  # Build a Powershell cmdlet call
  def self.build_call(cmdlet, args = {}, _ps_version: 5)
    return [cmdlet.gsub('@Args', '')].flatten if args.empty?

    id = (cmdlet.hash ^ args.hash).abs.to_s(36)
    optmap = "Fog#{id}"

    commands = []
    commands += build_optmap(_optmap_name: optmap, _ps_version:, **args)
    commands << if cmdlet.include? '@Args'
                  cmdlet.gsub('@Args', "@#{optmap}")
                else
                  "#{cmdlet} @#{optmap}"
                end
    commands
  end

  # Convert Ruby data to PowerShel
  def self.shell_quote(data, always: false)
    case data
    when String
      if !data.start_with?('$') && (data =~ /(^$)|\s/ || always)
        data.gsub('`', '``')
            .gsub(/\0/, '`0')
            .gsub("\n", '`n')
            .gsub("\r", '`r')
            .inspect
            .gsub('\"', '`"')
            .gsub('\\\\', '\\')
      else
        data
      end
    when Hash
      raise 'Hashes need to be run through build_optmap'
    when Array
      "@(#{data.map { |e| shell_quoted(e, always: true) }.join(', ')})"
    when FalseClass
      '$false'
    when TrueClass
      '$true'
    when nil
      '$null'
    else
      shell_quoted data.to_s
    end
  end
end

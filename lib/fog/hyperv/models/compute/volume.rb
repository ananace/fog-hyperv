module Fog
  module Compute
    class Hyperv
      class Volume < Fog::Model
        identity :id

        # :HDD, :FDD, :DVD
        attribute :type

        def initialize(attributes = {})
          # TODO:
          # switch <something>
          # case HardDiskDrive
          #   type = :HDD
          # case FloppyDiskDrive
          #   type = :FDD
          # case DvdDrive
          #   type = :DVD
          # end
        end
      end
    end
  end
end

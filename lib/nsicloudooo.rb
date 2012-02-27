require 'client'
require 'fake_server'

module NSICloudooo
    include Client
    include FakeServer
end

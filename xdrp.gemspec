Gem::Specification.new do |s|
  s.name = 'xdrp'
  s.version = '0.1.2'
  s.summary = 'A basic macro recorder for GNU/Linux which uses program ' + 
      'xinput to capture input events.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/xdrp.rb']
  s.add_runtime_dependency('xdo', '~> 0.0', '>=0.0.4')
  s.add_runtime_dependency('rxfhelper', '~> 1.0', '>=1.0.0')
  s.add_runtime_dependency('xinput_wrapper', '~> 0.7', '>=0.7.0')    
  s.signing_key = '../privatekeys/xdrp.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/xdrp'
end

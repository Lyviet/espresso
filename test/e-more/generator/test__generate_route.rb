module EGeneratorTest__Route
  Spec.new self do
    include GeneratorSpecHelper
    cleanup

    Should 'fail cause not inside Espresso application' do
      output = %x[#{GENERATOR__BIN} g:r Foo bar]
      check {$?.exitstatus} > 0
      expect(output) =~ /not a generated Espresso application/
    end

    Dir.chdir GENERATOR__DST_ROOT do
      Testing do


        %x[#{GENERATOR__BIN} g:p App]
        check {$?.exitstatus} == 0

        Dir.chdir 'App' do
          
          Should 'fail with "controller does not exists"' do
            output = %x[#{GENERATOR__BIN} g:r Foo bar]
            check {$?.exitstatus} > 0
            expect(output) =~ /controller does not exists/
          end

          %x[#{GENERATOR__BIN} g:c Foo]
          check {$?.exitstatus} == 0

          Should 'create a basic route' do
            %x[#{GENERATOR__BIN} g:r Foo bar]
            check {$?.exitstatus} == 0

            file = 'base/controllers/foo/bar_action.rb'
            is(File).file? file
            expect(File.read file) =~ /def\s+bar\n/
          end

          Should 'create a route with args' do
            %x[#{GENERATOR__BIN} g:r Foo argued a, b, c=nil]
            check {$?.exitstatus} == 0

            file = 'base/controllers/foo/argued_action.rb'
            is(File).file? file
            expect(File.read file) =~ /def\s+argued\s+a\,\s+b\,\s+c=nil\n/
          end
          
          Should 'create a route with setups' do
            %x[#{GENERATOR__BIN} g:r Foo setuped engine:Slim format:html]
            check {$?.exitstatus} == 0

            file = 'base/controllers/foo/setuped_action.rb'
            is(File).file? file
            code = File.read file
            expect(code) =~ /format_for\s+:setuped\,\s+\Whtml/
            expect(code) =~ /before\s+:setuped\s+do[\n|\s]+engine\s+:Slim/
            expect(code) =~ /def\s+setuped/m
          end

          Should 'create a route with args and setups' do
            %x[#{GENERATOR__BIN} g:r Foo seturgs a, b, c=nil engine:Slim format:html]
            check {$?.exitstatus} == 0

            file = 'base/controllers/foo/seturgs_action.rb'
            is(File).file? file
            code = File.read file
            expect(code) =~ /format_for\s+:seturgs\,\s+\Whtml/
            expect(code) =~ /before\s+:seturgs\s+do[\n|\s]+engine\s+:Slim/
            expect(code) =~ /def\s+seturgs\s+a\,\s+b\,\s+c=nil/m
          end

          Should 'correctly convert route into file and method names' do
            {
              'bar/baz' => 'bar__baz',
              'bar-baz' => 'bar___baz',
              'bar.baz' => 'bar____baz',
            }.each_pair do |route, meth|
              Testing "#{route} to #{meth}" do
                %x[#{GENERATOR__BIN} g:r Foo #{route}]
                check {$?.exitstatus} == 0
                file = "base/controllers/foo/#{meth}_action.rb"
                is(File).file? file
                expect(File.read file) =~ /def\s+#{meth}/
              end
            end
          end

          Should 'inherit engine defined at controller generation' do
            %x[#{GENERATOR__BIN} g:c Pages e:Slim]
            check {$?.exitstatus} == 0

            %x[#{GENERATOR__BIN} g:r Pages edit]
            check {$?.exitstatus} == 0
            is(File).file? 'base/views/pages/edit.slim'

            And 'override it when explicitly given' do
              %x[#{GENERATOR__BIN} g:r Pages create e:Haml]
              check {$?.exitstatus} == 0
              is(File).file? 'base/views/pages/create.haml'
            end
          end

        end
      end
      cleanup

      Should 'inherit engine defined at project generation' do
        %x[#{GENERATOR__BIN} g:p App e:Slim]
        check {$?.exitstatus} == 0
        
        Dir.chdir 'App' do
          %x[#{GENERATOR__BIN} g:c Foo]
          check {$?.exitstatus} == 0

          %x[#{GENERATOR__BIN} g:r Foo bar]
          check {$?.exitstatus} == 0

          is(File).file? 'base/views/foo/bar.slim'
        end
      end
      cleanup

      Should 'create multiple routes' do
        %x[#{GENERATOR__BIN} g:p App]
        check {$?.exitstatus} == 0
        
        Dir.chdir 'App' do
          %x[#{GENERATOR__BIN} g:c Foo]
          check {$?.exitstatus} == 0
          
          %x[#{GENERATOR__BIN} g:rs Foo a b c e:Slim]
          check {$?.exitstatus} == 0

          %w[a b c].each do |c|
            file = "base/controllers/foo/#{c}_action.rb"
            is(File).file? file
            code = File.read file
            expect {code} =~ /class Foo\n/i
            is(File).file? "base/views/foo/#{c}.slim"
          end
        end
      end
      cleanup
    end
  end
end

module Travis
  module Build
    class Script
      class Rust < Script
        RUST_RUSTUP = 'https://sh.rustup.rs'
        RUSTUP_CMD = "curl -sSf https://sh.rustup.rs | sh -s -- --default-toolchain=$TRAVIS_RUST_VERSION -y"

        DEFAULTS = {
          rust: 'stable',
        }

        def export
          super

          sh.export 'TRAVIS_RUST_VERSION', config[:rust].to_s.shellescape, echo: false
        end

        def setup
          super

          sh.fold('rustup-install') do
            sh.echo 'Installing Rust', ansi: :yellow
            unless app_host.empty?
              sh.cmd "curl -sSf https://#{app_host}/files/rustup-init.sh | sh -s -- --default-toolchain=$TRAVIS_RUST_VERSION -y", echo: true, assert: false
              sh.if "$? -ne 0" do
                sh.cmd RUSTUP_CMD, echo: true, assert: true
              end
            else
              sh.cmd RUSTUP_CMD, echo: true, assert: true
            end
            sh.export 'PATH', "$HOME/.cargo/bin:$PATH"
          end
        end

        def announce
          super

          sh.cmd 'rustc --version'
          sh.cmd 'cargo --version'
          sh.echo ''
        end

        def script
          sh.cmd 'cargo build --verbose'
          sh.cmd 'cargo test --verbose'
        end

        def setup_cache
          if data.cache?(:cargo)
            sh.fold 'cache.cargo' do
              directory_cache.add "$HOME/.cargo", "target"
            end
          end
        end

        def cache_slug
          super << "--cargo-" << version
        end

        def use_directory_cache?
          super || data.cache?(:cargo)
        end

        private

          def version
            config[:rust].to_s
          end
      end
    end
  end
end

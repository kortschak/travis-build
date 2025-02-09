require 'spec_helper'

describe Travis::Build::Script::Rust, :sexp do
  let(:data)   { payload_for(:push, :rust, config: config) }
  let(:config) { {} }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }
  it           { store_example }

  it_behaves_like 'a bash script'

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=rust'] }
    let(:cmds) { ['cargo build --verbose'] }
  end

  it_behaves_like 'a build script sexp'

  it 'downloads and installs Rust' do
    should include_sexp [:cmd, %r(curl -sSf #{Travis::Build::Script::Rust::RUST_RUSTUP} | sh -s -- --default-toolchain=$TRAVIS_RUST_VERSION -y), assert: true, echo: true, timing: true]
  end

  it 'announces rust version' do
    should include_sexp [:cmd, 'rustc --version', assert: true, echo: true]
  end

  it 'announces cargo version' do
    should include_sexp [:cmd, 'cargo --version', assert: true, echo: true]
  end

  it 'runs cargo test' do
    should include_sexp [:cmd, 'cargo test --verbose', echo: true, timing: true]
  end

  it 'runs cargo build' do
    should include_sexp [:cmd, 'cargo build --verbose', echo: true, timing: true]
  end

  it 'runs cargo test' do
    should include_sexp [:cmd, 'cargo test --verbose', echo: true, timing: true]
  end

  context "when Rust version is an array" do
    let(:version) { 'nightly' }
    let(:data) { payload_for(:push, :rust, config: { rust: [version] }) }

    it 'sets TRAVIS_RUST_VERSION environment variables the first version specified' do
      should include_sexp [:export, ['TRAVIS_RUST_VERSION', version]]
    end
  end

  context "when cache is configured" do
    let(:options) { { fetch_timeout: 20, push_timeout: 30, type: 's3', s3: { bucket: 's3_bucket', secret_access_key: 's3_secret_access_key', access_key_id: 's3_access_key_id' } } }
    let(:data)   { payload_for(:push, :rust, config: { cache: 'cargo' }, cache_options: options) }

    it 'caches desired directories' do
      should include_sexp [:cmd, %r[rvm \$\(travis_internal_ruby\) --fuzzy do \$CASHER_DIR/bin/casher --name cache-linux-[0-9a-f]+--cargo-stable cache add \$\{TRAVIS_HOME\}/.cargo target \$\{TRAVIS_HOME\}/.rustup \$\{TRAVIS_HOME\}/.cache/sccache], timing: true]
    end

    it 'removes $HOME/.cargo/registry/src' do
      should include_sexp [:cmd, 'rm -rf "$HOME/.cargo/registry/src"']
    end

    context "when on macOS" do
      let(:data)   { payload_for(:push, :rust, config: { os: 'osx', cache: 'cargo' }, cache_options: options) }

      it 'caches desired directories' do
        should include_sexp [:cmd, %r[rvm \$\(travis_internal_ruby\) --fuzzy do \$CASHER_DIR/bin/casher --name cache-osx-[0-9a-f]+--cargo-stable cache add \$\{TRAVIS_HOME\}/.cargo target \$\{TRAVIS_HOME\}/.rustup \$\{TRAVIS_HOME\}/Library/Caches/Mozilla\.sccache], timing: true]
      end
    end
  end
end

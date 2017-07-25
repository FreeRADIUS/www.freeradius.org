# Running tests

You will need
- OpenResty
- Perl - Test::NGINX
- Perl - JSON
- Perl - Tie::Autotie
- Perl - Prove
- LuaJIT - Lua file system

## OSX
### Install CPAN dependencies
```bash
sudo cpan install Tie::Autotie JSON Test::Nginx Test::Nginx::Socket
```

### Install OpenResty dependencies
```bash
brew update
brew install pcre openssl
```

### Download and uncompress OpenResty
```bash
OPENRESTY_VERSION=1.9.7.4

mkdir -p /usr/local/src
cd /usr/local/src/
curl https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz > openresty-${OPENRESTY_VERSION}.tar.gz
tar -xzf ./openresty-${OPENRESTY_VERSION}.tar.gz
cd openresty-${OPENRESTY_VERSION}
```

### Configure and build OpenResty against brewed dependencies
```bash
./configure \
   --with-cc-opt="-I/usr/local/opt/openssl/include/ -I/usr/local/opt/pcre/include/" \
   --with-ld-opt="-L/usr/local/opt/openssl/lib/ -L/usr/local/opt/pcre/lib/" \
   -j8 \
   --prefix=/usr/local/openresty
make
sudo make install
```

### Build a special OpenResty / LuaJIT version of LuaRocks
```bash
LUAROCKS_VERSION=2.3.0

mkdir -p /usr/local/src
cd /usr/local/src/
curl http://keplerproject.github.io/luarocks/releases/luarocks-${LUAROCKS_VERSION}.tar.gz > luarocks-${LUAROCKS_VERSION}.tar.gz
tar -xzf luarocks-${LUAROCKS_VERSION}.tar.gz
cd luarocks-${LUAROCKS_VERSION}

./configure --prefix=/usr/local/openresty/luajit \
    --with-lua=/usr/local/openresty/luajit/ \
    --lua-suffix=jit-2.1.0-beta1 \
    --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1
make build
sudo make install
sudo make boostrap
```

### Install lua dependencies using special OpenResty / LuaJIT version of LuaRocks
```bash
sudo /usr/local/openresty/luajit/bin/luarocks install luafilesystem
sudo /usr/local/openresty/luajit/bin/luarocks install lua-resty-http
sudo /usr/local/openresty/luajit/bin/luarocks install lua-zlib
```

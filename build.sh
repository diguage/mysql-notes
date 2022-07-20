#!/bin/bash
#
# 构建脚本

base_dir=`pwd`
origin_file_name=index
adoc_file_name=${origin_file_name}.adoc
origin_html_file_name=${origin_file_name}-html.html
web_html_file_name=index.html
style_dir=assets/styles/

# 确保 asciidoctor 命令被安装
asciidoctor=`which asciidoctor`
if [ ! -n `which asciidoctor` ]; then
  echo "installing asciidoctor..."
  gem install asciidoctor
  asciidoctor=`which asciidoctor`
fi

# 确保 wkhtmltopdf 命令被安装
wkhtmltopdf=`which wkhtmltopdf`
if [ ! -n `which wkhtmltopdf` ]; then
  echo "installing wkhtmltopdf..."
  if [[ `uname` == Darwin* ]]; then
    brew cask install wkhtmltopdf
  else
    sudo apt install -y wkhtmltopdf
  fi
  wkhtmltopdf=`which wkhtmltopdf`
fi

# 解决 Mac 与 Linux 中 sed 处理不统一的问题
gsed=`which sed`
if [[ `uname` == Darwin* ]]
then
  gsed=`which gsed`
fi

# 确保 cssnano 命令被安装
cssnano=`which cssnano`
if [ ! -n `which cssnano` ]; then
  echo "installing cssnano..."
  npm install cssnano-cli --g --registry=https://registry.npm.taobao.org
  cssnano=`which cssnano`
fi

# 确保 html-minifier 命令被安装
htmlminifier=`which html-minifier`
if [ ! -n `which html-minifier` ]; then
  echo "installing html-minifier..."
  npm install html-minifier -g --registry=https://registry.npm.taobao.org
  htmlminifier=`which html-minifier`
fi

# 删除以前的编译结果
rm -rf *.html *.pdf
ehco -e "\nremove the last processing result"
# $style_dir

## Web ###########

# Web
$asciidoctor -a toc=left \
             -a stylesdir=$style_dir \
             -a linkcss \
             -r asciidoctor-multipage \
             -b multipage_html5 \
             -D . \
             $adoc_file_name

echo -e "\nbuild OK."

cd ./$style_dir

pwd

echo -e "\ncompress css"
for f in `ls .`
do
  # 压缩 CSS
  $cssnano $f $f
  echo -e "  $f"
done

cd $base_dir

for f in `ls ./*.html`
do
  # 调整样式
  $gsed -i "s/<\/head>/<style>a{text-decoration:none;}.img_bk{text-align:center;}p>code,strong>code{color: #d14 !important;background-color: #f5f5f5 !important;border: 1px solid #e1e1e8;white-space: nowrap;border-radius: 3px;}<\/style><\/head>/" $f
  echo -e "\nadd style to $f"

  # 替换 Font Awesome
  $gsed -i "s/https:\/\/cdnjs.cloudflare.com\/ajax\/libs\/font-awesome\/4.7.0\/css\/font-awesome.min.css/https:\/\/cdn.jsdelivr.net\/npm\/font-awesome@4.7.0\/css\/font-awesome.min.css/" $f
  echo -e "\nreplace font-awesome for $f"

  if [ "$f" != "./preface.html" ]; then
    # 增加打赏码
    $gsed -i "s|<div id=\"content\">|<div id=\"content\"><div class=\"sect2\"><h3 id=\"_友情支持\">友情支持</h3><div class=\"paragraph\"><p>如果您觉得这个笔记对您有所帮助，看在D瓜哥码这么多字的辛苦上，请友情支持一下，D瓜哥感激不尽，😜</p></div><table class=\"tableblock frame-none grid-all stretch\"><colgroup><col style=\"width: 50%;\"><col style=\"width: 50%;\"></colgroup><tbody><tr><td class=\"tableblock halign-center valign-top\"><p class=\"tableblock\"><span class=\"image\"><img src=\"assets/images/alipay.png\" alt=\"支付宝\" width=\"85%\" title=\"支付宝\"></span></p></td><td class=\"tableblock halign-center valign-top\"><p class=\"tableblock\"><span class=\"image\"><img src=\"assets/images/wxpay.jpg\" alt=\"微信\" width=\"85%\" title=\"微信\"></span></p></td></tr></tbody></table><div class=\"paragraph\"><p>有些打赏的朋友希望可以加个好友，欢迎关注D瓜哥的微信公众号，这样就可以通过公众号的回复直接给我发信息。</p></div><div class=\"paragraph\"><p><span class=\"image\"><img src=\"assets/images/wx-jikerizhi.png\" alt=\"wx jikerizhi\" width=\"98%\"></span></p></div><div class=\"admonitionblock tip\"><table><tbody><tr><td class=\"icon\"><i class=\"fa icon-tip\" title=\"Tip\"></i></td><td class=\"content\"><strong>公众号的微信号是: <code>jikerizhi</code></strong>。<em>因为众所周知的原因，有时图片加载不出来。如果图片加载不出来可以直接通过搜索微信号来查找我的公众号。</em></td></tr></tbody></table></div></div>|" $f
    echo -e "\nadd qrcode for $f"
  fi
done

# $htmlminifier -c html-minifier.config.json $origin_html_file_name -o $web_html_file_name

# cp $origin_html_file_name $web_html_file_name

echo -e "\n`date '+%Y-%m-%d %H:%M:%S'` build"

if [ -n "$1" ]; then
    echo -e "\nstart rsync..."

    rsync -avz --exclude=".*" ./assets ./*.html  ubuntu@notes.diguage.com:/var/www/diguage.com/notes/mysql
    
    echo -e "\n`date '+%Y-%m-%d %H:%M:%S'` deploy"
fi
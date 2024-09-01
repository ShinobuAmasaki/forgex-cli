このパッケージは、Fortran Regular Expression (Forgex) を対話的に実行する`forgex-cli`というコマンドラインツールを提供します。
`forgex-cli`コマンドはもともとForgexの一部として提供されていましたが、Forgexバージョン3.5より、本リポジトリとして
分離されました。

## 動作確認

このソフトウェアの動作は以下のコンパイラで確認されています。

- GNU Fortran (`gfortran`) v13.2.1
- Intel Fortran Compiler (`ifx`) 2024.0.0 20231017

Fortran Package Manager(`fpm`)を使用することを前提にしています。

## インストール

### ソースコードの入手
リポジトリをクローンします。

```shell
git clone https://github.com/shinobuamasaki/forgex-cli
```

もしくは最新のソースファイルをダウンロードします。

```shell
wget https://github.com/ShinobuAmasaki/forgex-cli/archive/refs/tags/v3.5.tar.gz
```
この場合は、ダウンロードしたアーカイブファイルを展開します。

```shell
tar xvzf v3.5.tar.gz
```

### ビルド

クローン、もしくは展開されたディレクトリに移動します。

```shell
cd forgex-cli
```

Fortran Package Managerの`fpm`コマンドを使用してビルドを実行します。

```shell
fpm build
```

これにより、依存関係が自動的に解決され、Forgexを含む`forgex-cli`がコンパイルされます。
ビルド後は`fpm run`コマンドを使用して、`forgex-cli`を実行することができます。

PATHの通ったディレクトリにインストールする場合は、`fpm install`を実行してください。
例えば次のようにします。

```shell
fpm install --prefix /usr/local
```

なお、`fpm build`や`fpm install`では`--profile release`オプションを指定して、最適化オプション等を有効にして
ビルド及びインストールすることができます。

## 使い方

この記事では、`forgex-cli`コマンドの基本的な使い方について解説します。
<!-- コマンド、サブコマンド、オプションフラグ、出力の読み方等の詳細についてはそれぞれの記事を参照してください。 -->

### コマンドライン・インターフェイス

現在、`find`と`debug`のコマンドと、以下のサブコマンド等が実行可能です。

```
forgex-cli
├── find
│    └── match
│         ├── lazy-dfa <pattern> <operator> <input text>
│         ├── dense <pattern> <operator> <input text>
│         └── forgex <pattern> <operator> <input text>
└── debug
      ├── ast <pattern>
      └── thompson <pattern>
```

`forgex-cli`のコマンドは次のように実行します

```
forgex-cli <command> <subcommand> ...
fpm run -- <command> <subcommand> ...
```

### 使用例

#### `find`コマンド

`find`コマンドと`match`サブコマンドを使用すると、エンジンを指定して、`.in.`と`.match.`演算子を用いた正規表現マッチングのベンチマークテストを実行することができます。

サブコマンドの後ろに、以下のエンジンのいずれかを指定します。
- `lazy-dfa`
- `dense`
- `forgex`

さらにその後ろには、正規表現パターン、演算子、入力テキストの順に、Forgexを使ってFortranコードを書くのと同じように指定します。
例えば、次のようになります。

```shell
forgex-cli find match lazy-dfa '([a-z]*g+)n?' .match. 'assign'
```

もしくは、`fpm run`を介して実行することもできます。

```shell
fpm run -- find match lazy-dfa '([a-z]*g+)n?' .match. 'assign'
```

いずれかを実行すると、以下のような実行結果が得られます。

<div class="none-highlight-user">

```
                pattern: ([a-z]*g+)n?
                   text: 'assign'
             parse time:        42.9μs
   extract literal time:        23.0μs
            runs engine:         T
       compile nfa time:        26.5μs
    dfa initialize time:         4.6μs
            search time:       617.1μs
        matching result:         T
 automata and tree size:     10324  bytes

========== Thompson NFA ===========
state    1: (?, 5)
state    2: <Accepted>
state    3: (n, 2)(?, 2)
state    4: (g, 7)
state    5: (["a"-"f"], 6)(g, 6)(["h"-"m"], 6)(n, 6)(["o"-"z"], 6)(?, 4)
state    6: (?, 5)
state    7: (?, 8)
state    8: (g, 9)(?, 3)
state    9: (?, 8)
=============== DFA ===============
   1 : ["a"-"f"]=>2
   2 : ["o"-"z"]=>2 ["h"-"m"]=>2 g=>3
   3A: n=>4
   4A:
state    1  = ( 1 4 5 )
state    2  = ( 4 5 6 )
state    3A = ( 2 3 4 5 6 7 8 )
state    4A = ( 2 4 5 6 )
===================================
```

</div>

#### `debug`コマンド

`debug`コマンドを使用すると、正規表現から構築された抽象構文木（AST）や非決定性有限オートマトン（NFA）の情報を得ることができます。

例えば、`debug`コマンドと`ast`サブコマンドに、正規表現パターン`foo[0-9]+bar`を与えて実行します。

```shell
forgex-cli debug ast 'foo[0-9]+bar'
```

そうすると、以下のように出力され、ASTの構造を知ることができます。

<div class="none-highlight-user">

```
        parse time:       133.8μs
      extract time:        36.8μs
 extracted literal:
  extracted prefix: foo
  extracted suffix: bar
memory (estimated):       848
(concatenate (concatenate (concatenate (concatenate (concatenate (concatenate "f" "o") "o") (concatenate [ "0"-"9";] (closure[ "0"-"9";]))) "b") "a") "r")
```

</div>

次にNFAの情報を得るには、`debug`コマンドと`thompson`サブコマンドを指定して、パターンを与えます。

```shell
forgex-cli debug thompson 'foo[0-9]+bar'
```

このコマンドの出力は、次のようになります。

```
        parse time:       144.5μs
  compile nfa time:        57.0μs
memory (estimated):     11589

========== Thompson NFA ===========
state    1: (f, 8)
state    2: <Accepted>
state    3: (r, 2)
state    4: (a, 3)
state    5: (b, 4)
state    6: (["0"-"9"], 9)
state    7: (o, 6)
state    8: (o, 7)
state    9: (?, 10)
state   10: (["0"-"9"], 11)(?, 5)
state   11: (?, 10)

Note: all segments of NFA were disjoined with overlapping portions.
===================================
```

### 注意

- コマンドライン引数に`--help`を指定すると、使用可能なオプションフラグに関する情報を取得できます。
- コマンドラインツール`forgex-cli`をWindows上のPowerShellで利用する場合、Unicode文字を正しく入出力するには、システムのロケールをUTF-8に変更する必要があります。

## To Do

- ドキュメントの公開
- CMakeによるビルドのサポート
- ✅️ デバッグおよびベンチマーク用のCLIツールを追加
- ✅️ 簡単な時間計測ツールの追加

## コーディング規約
本プロジェクトに含まれるすべてのコードは、3スペースのインデントで記述されます。

## 謝辞
`forgex-cli`のコマンドラインインターフェイスの設計については、Rust言語の`regex-cli`を参考にしました。

## 参考文献
1. [rust-lang/regex/regex-cli](https://github.com/rust-lang/regex/tree/master/regex-cli)

## ライセンス
このプロジェクトはMITライセンスで提供されるフリーソフトウェアです
（cf. [LICENSE](https://github.com/ShinobuAmasaki/forgex-cli/blob/main/LICENSE)）。

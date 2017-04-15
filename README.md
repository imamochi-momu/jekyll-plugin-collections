# jekyll-plugin-collections

コレクションに関するいろいろなプラグイン。

## インストール

`<Jekyll Dir>/plugins/collections.rb`を突っ込むだけ。

## 使い方

### コレクション内の各ファイル

コレクションの各YAMLヘッダーに以下の要素を追加する。

```
link_previous: <前にリンクするファイル名>
link_next: <次にリンクするファイル名>
link_up: <上にリンクするファイル名>
link_down: <下にリンクするファイル名>
```

### ページ一覧

`_layouts/collection_list.html`としてレイアウトを作成する。

サンプルは以下。

```
<h1 id="page-title">{{ page.title_detail }}</h1>
<article class="post-content">
  <ul>
    {% for post in page.info %}
    <li class="nest{{ post.level }}"><a href="{{ post.page.url }}">{% if post.page.title != null %}{{ post.page.title }}{% else %}{{ post.page.url }}{% endif %}</a></li>
    {% endfor %}
  </ul>
</article>
```

### ナビゲーション表示

コレクション用のレイアウトファイルに以下を追加する。

```
{% collection_navi %}
```

### 指定のコレクションにおけるナビゲーション作成

ページ一覧と同様の内容を、指定の位置に追加する。
`target`には出力するコレクション名を指定する。

```
{% collection_items target %}
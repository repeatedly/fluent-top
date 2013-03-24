# fluent-top

fluent-top is a top-like command line utility to display Fluentd status.

fluent-top is based on [resque-top](https://github.com/miyagawa/resque-top)

## ScreenShot

![](http://dl.dropbox.com/u/374829/fluent_top_ss.png)

## Installation

### gem

```
gem install fluent-top
```

## Usage

```
fluent-top
```

### NOTE

**fluent-top** depends on drb in **in_debug_agent** .
So you should put **in_debug_agent** source in your configuration.

## Copyright

<table>
  <tr>
    <td>Author</td><td>Masahiro Nakagawa <repeatedly@gmail.com></td>
  </tr>
  <tr>
    <td>Copyright</td><td>Copyright (c) 2013- Masahiro Nakagawa</td>
  </tr>
  <tr>
    <td>License</td><td>MIT License</td>
  </tr>
</table>
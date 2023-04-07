========================
Language Server Protocol
========================

The Language Server Protocol (LSP) is an open protocol that allows for easy
code completion, real-time compiler linting, and much more.

clangd
------

There are LSP servers for nearly every mainstream programming language, but
we're going to be using the C LSP implementation, `clangd`. Follow
`this guide <https://clangd.llvm.org/installation.html>`_ to install and setup
`clangd` in your programming environment.

Jump to Definition
------------------

One of the most useful features of LSP is its `jump-to-definition` feature.
If you use VSCode: hover over any function, structure, or variable and
`<Ctrl - Left Click>` (`<Cmd - Left Click>` on macOS). This will jump to the
definition of said function, structure, or variable. Use this to navigate
large codebases.

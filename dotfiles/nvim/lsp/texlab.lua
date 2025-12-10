return {
  settings = {
    texlab = {
      chktex = { onOpenAndSave = true },
      formatterLineLength = 100,
      forwardSearch = {
        executable = "sioyek",
        args = { "--forward-search-file", "%f", "--forward-search-line", "%l", "%p" },
      },
    },
  },
}

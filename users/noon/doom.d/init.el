;; default to mononoki
(set-face-attribute 'default nil
                    :family "mononoki"
                    :height 120
                    :weight 'normal
                    :width  'normal)

(doom!
  :input
  :completion
  company
  vertico

  :lang
  agda
  markdown
  org

  :ui
  (emoji +unicode)
  doom
  doom-dashboard
  indent-guides
  ophints
)

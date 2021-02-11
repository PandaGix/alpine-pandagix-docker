;; PandaGix using the following channels
;; GPL2©2021 BambooGeek@PandaGix

(list
    (channel (inherit (car %default-channels))
        (url "https://git.nju.edu.cn/nju/guix.git")
    ;;  (branch "version-1.2.0")   
        (commit "dffc918af6cf6e1ce942dd329d210271ced1205d")
    )
    (channel (name 'nonguix)
        (url "https://git.nju.edu.cn/nju/nonguix")
        (commit "73b11e7928cbb76ebec41edb0307b130057ade5f")
    )
)

;; PandaGix using the following channels
;; GPL2©2021 BambooGeek@PandaGix

(list
    (channel (inherit (car %default-channels))
        (url "https://git.nju.edu.cn/nju/guix.git")
    ;;  (branch "version-1.2.0")   
        (commit "a31b72655d1127dfd67508ab2625fe518b83d009")
    )
    (channel (name 'nonguix)
        (url "https://git.nju.edu.cn/nju/nonguix")
        (commit "9e2686872fe48ee815622b91c2f65b6cc059594d")
    )
)

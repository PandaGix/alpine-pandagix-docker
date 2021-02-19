(list 
    (channel
                (name 'guix)
                (url "https://git.nju.edu.cn/nju/guix.git")
                (commit "6941dbf958a2294e0a058af3498df9c46a6a1e50")
                (introduction
		(make-channel-introduction
          	"9edb3f66fd807b096b48283debdcddccfea34bad" ; from guix/channels.scm, said 20200526
          	(openpgp-fingerprint
           	"BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA" ; from guix/channels.scm
		)))) ; end of this (channel
    (channel
                (name 'nonguix)
                (url "https://git.nju.edu.cn/nju/nonguix.git")
                (commit "1d58ea1acadba57b34669c8a3f3d9f0de8d339b5")
                (introduction
		(make-channel-introduction
          	"897c1a470da759236cc11798f4e0a5f7d4d59fbc"
          	(openpgp-fingerprint
           	"2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5"
		)))) ; end of this (channel
) ; end of (list


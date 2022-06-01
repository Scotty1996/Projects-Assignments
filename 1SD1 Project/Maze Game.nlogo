turtles-own [ home-pos new-heading ]
enemys-own [ flag? move-patch]
patches-own[father Cost-path visited? active?]
breed [ players player ]
breed [ monsters monster ]
breed [ enemys enemy ]
breed [ flags flag]

globals [

  p-valids         ;; holds valid patches for search algorithim
  Start            ;; holds start point for algorithim
  Goal             ;;holds goal point for algorithim
  Final-Cost       ;; holds the cost of the path for the algorithim


  level            ;; current level
  level-over?      ;; true when a level is complete

  player-lives     ;; remaining lives

  red-lives        ;; enemy 1 lives
  yellow-lives     ;; enemy 2 lives
  blue-lives       ;; enemy 3 lives

  player-score     ;; player score

  red-score        ;; enemy 1 score
  yellow-score     ;; enemy 2 score
  blue-score       ;; enemy 3 score


  dead?            ;; true when player loses a life

  red-dead?        ;; enemy death
  yellow-dead?     ;; enemy death
  blue-dead?       ;; enemy death

  speed            ;; player speed
  red-speed        ;; enemy 1 speed
  yellow-speed     ;; enemy 2 speed
  blue-speed       ;; enemy 3 speed
  monster-speed    ;; monster speed

  count-down       ;; Timer
  visible?         ;; Controls flag-turtle interaction
  all-dead         ;; if all enemies are dead
  gamer-over?      ;; Terminates

  tool which-enemy ;; variable needed to properly load level.
]

;; Player, color green, turtle 1, index 0
;; Monster, color brown, turtle 2, index 1
;; Flag, color purple, turtle 3, index 2
;; Enemy 1, color red (15), turtle 4, index 3
;; Enemy 2, color yellow (45), turtle 5, index 4
;; Enemy 3, color blue (95), turtle 6, index 5

;;;;;;;;;;;;;;;;;;;;;;;;
;;; Setup Procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;;

to new  ;; Observer Button
  clear-all

  set level 1

  load-map

  set level-over? false

  reset-ticks
end

to load-map  ;; Observer Procedure
  ;; Filename of Level Files
  let maps ["playermap1.csv" "playermap2.csv" "playermap3.csv"]

  ifelse ((level - 1) < length maps)
  [ import-world item (level - 1) maps



    set player-lives 3

    set red-lives 3
    set yellow-lives 3
    set blue-lives 3

    set player-score 0

    set red-score 0
    set yellow-score 0
    set blue-score 0

    set dead? false

    set red-dead? false
    set yellow-dead? false
    set blue-dead? false

    set speed 0.6
    set red-speed 0.6
    set yellow-speed 0.6
    set blue-speed 0.6
    set monster-speed 1

    set all-dead 0

    set visible? true

    ask players
    [
      set home-pos list xcor ycor
      set count-down 10
    ]
    ask monsters
    [ set home-pos list xcor ycor ]

     ask patches
  [
    set father nobody
    set Cost-path 0
    set visited? false
    set active? false
  ]
    set p-valids patches with [pcolor != grey and pcolor != orange ]

    ask enemys
    [
      set move-patch nobody
      set home-pos list xcor ycor
      set count-down 10
      set flag? false
    ]
    ask flags
    [ set home-pos list xcor ycor ]
  ]
  [ set level 1
    load-map ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Runtime Procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;
; Patch report to estimate the total expected cost of the path starting from
; in Start, passing through it, and reaching the #Goal
to-report Total-expected-cost [#Goal]
  report Cost-path + Heuristic #Goal
end

; Patch report to reurtn the heuristic (expected length) from the current patch
; to the #Goal
to-report Heuristic [#Goal]
  report distance #Goal
end

to map-enemy
  ;;Set the relative starting point and goal point for the enemy turtle
  ask enemys [
  set Start patch-here
    ]
  ;;Find the goal aka the flag
  (ifelse
  flag visible? = true
  [
    ask flags [set Goal patch-here]
  ]
  flag visible? = false
  [
    ask players [set goal patch-here]
  ])
end

; A* algorithm. Inputs:
;   - #Start     : starting point of the search.
;   - #Goal      : the goal to reach.
;   - #valid-map : set of agents (patches) valid to visit.
; Returns:
;   - If there is a path : list of the agents of the path.
;   - Otherwise          : false
to-report A* [#Start #Goal #valid-map]
  ; clear all the information in the patches
  ask #valid-map with [visited?]
  [
    set father nobody
    set Cost-path 0
    set visited? false
    set active? false
  ]
  ; Active the staring point to begin the searching loop
  ask #Start
  [
    set father self
    set visited? true
    set active? true
  ]
  ; exists? indicates if in some instant of the search there are no options to
  ; continue. In this case, there is no path connecting #Start and #Goal
  let exists? true
  ; The searching loop is executed while we don't reach the #Goal and we think
  ; a path exists
  while [not [visited?] of #Goal and exists?]
  [
    ; We only work on the valid pacthes that are active
    let options #valid-map with [active?]
    ; If any
    ifelse any? options
    [
      ; Take one of the active patches with minimal expected cost
      ask min-one-of options [Total-expected-cost #Goal]
      [
        ; Store its real cost (to reach it) to compute the real cost
        ; of its children
        let Cost-path-father Cost-path
        ; and deactivate it, because its children will be computed right now
        set active? false
        ; Compute its valid neighbors
        let valid-neighbors neighbors4 with [member? self #valid-map]
        ask valid-neighbors
        [

          let t ifelse-value visited? [ Total-expected-cost #Goal] [2 ^ 20]

          if t > (Cost-path-father + distance myself + Heuristic #Goal)
          [
            ; The current patch becomes the father of its neighbor in the new path
            set father myself
            set visited? true
            set active? true
            ; and store the real cost in the neighbor from the real cost of its father
            set Cost-path Cost-path-father + distance father
            set Final-Cost precision Cost-path 3
          ]
        ]
      ]
    ]
    ; If there are no more options, there is no path between #Start and #Goal
    [
      set exists? false
    ]
  ]
  ; After the searching loop, if there exists a path
  ifelse exists?
  [
    ; We extract the list of patches in the path, form #Start to #Goal
    ; by jumping back from #Goal to #Start by using the fathers of every patch
    let current #Goal
    set Final-Cost (precision [Cost-path] of #Goal 3)
    let rep (list current)
    While [current != #Start]
    [
      set current [father] of current
      set rep fput current rep
    ]
    report rep
  ]
  [
    ; Otherwise, there is no path, and we return False
    report false
  ]
end

; Axiliary procedure to lunch the A* algorithm between  patches
to look-for-goal
  set Start patch-here

  ; Compute the path between Start and Goal
  let path   A* Start Goal p-valids
  ; If any...
  if path != false [if color = 15
    [ ask enemys with [color = 15][
       move-to one-of neighbors4 with [member? self path]
      move-enemys
      ;;move-to one-of patches with[ neighbors4 = true and   visited? = true]

      ]
  ]

  if color = 45
  [  ask enemys with [color = 45][
      move-to one-of neighbors4 with [member? self path]
      move-enemys
      ;; move-to one-of patches with[ neighbors4 = true and   path = true]
      ]
  ]

  if color = 95
  [  ask enemys with [color = 95][
      move-to one-of neighbors4 with [member? self path]
      move-enemys
      ;;move-to one-of patches with[ neighbors4 = true and   path = true]
      ]
  ]]
    ; Set the Goal and the new Start point
  set Start Goal
end


to play  ;; Observer Forever Button

  player-lives-control
  player-score-control

  enemy-lives-control
  enemy-score-control

  ;; special win condition
  if all-dead = 3
  [ set level-over? true
    user-message "You Win - Last Man Standing" ]

  (ifelse
    level-over? = true and level != 3
    [ (ifelse
      player-score = 3 or all-dead = 3
      [ user-message "Prepare - Next Level!"
        set level level + 1
        load-map
        set level-over? false
        stop ]
      player-score != 3 or all-dead != 3
      [ user-message "Unlucky - Try Again!"
        set level level
        load-map
        set level-over? false
        stop ])
    ]
    level-over? = true and level = 3
    [ user-message "Congratulations - Game Completed!"
      stop ])

  every speed ;; player speed
  [ move-player ]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  every red-speed ;; red speed
  [
    ask enemys with [ color = 15 ]
      [ ;;Find the goal aka the flag
  ask flags [if visible? = true
  [
    ask flags[set Goal patch-here]
  ]]
  ask flags [if  visible? = false
  [ask players[
    if shape = "playerflag"[
        ask players [set goal patch-here]]]]

  ask enemys[if color = 15 and shape = "enemyflag"
      [ask enemys with [color = 15][set goal patch -9 9]]
]

  ask enemys[if color = 45 and shape = "enemyflag"
      [ask enemys with [color = 45][set goal patch-here]]
]

  ask enemys[if color = 95 and shape = "enemyflag"
      [ask enemys with [color = 95][set goal patch-here]]
]]

        look-for-goal]
    ;;[ move-enemys ]
   ]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  every yellow-speed ;; yellow speed
  [
    ask enemys with [ color = 45 ]
    [
       ;;Find the goal aka the flag
  ask flags [if visible? = true
  [
    ask flags[set Goal patch-here]
  ]]
  ask flags [if  visible? = false
  [ask players[
    if shape = "playerflag"[
        ask players [set goal patch-here]]]]

  ask enemys[if color = 15 and shape = "enemyflag"
      [ask enemys with [color = 15][set goal patch-here]]
]

  ask enemys[if color = 45 and shape = "enemyflag"
      [ask enemys with [color = 45][set goal patch 9 9]]
]

  ask enemys[if color = 95 and shape = "enemyflag"
      [ask enemys with [color = 95][set goal patch-here]]
]]

      look-for-goal]

   ;; [ move-enemys ]
  ]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  every blue-speed ;; blue speed
  [
    ask enemys with [ color = 95 ]
    ;;[ move-enemys ]
    [
       ;;Find the goal aka the flag
  ask flags [if visible? = true
  [
    ask flags[set Goal patch-here]
  ]]
  ask flags [if  visible? = false
  [ask players[
    if shape = "playerflag"[
        ask players [set goal patch-here]]]]

  ask enemys[if color = 15 and shape = "enemyflag"
      [ask enemys with [color = 15][set goal patch-here]]
]

  ask enemys[if color = 45 and shape = "enemyflag"
      [ask enemys with [color = 45][set goal patch-here]]
]

  ask enemys[if color = 95 and shape = "enemyflag"
      [ask enemys with [color = 95][set goal patch 9 -9]]
]]

      look-for-goal]


  ]

  every monster-speed ;; monster speed
  [
    ask monsters [ move-monsters ]
  ]

  display

end

to player-speed-control

  (ifelse
    shape = "player"
    [ set speed 0.6 ]
    shape = "playerflag"
    [ set speed 0.8 ])

end

to player-lives-control

  (ifelse
  dead? = true
  [
    if player-lives != 0
    [ set player-lives player-lives - 1
      if  player-lives = 0
      [ set level-over? true
        user-message "Game Over - No Lives Left!" ]
      set dead? false
    ]
  ]
  player-lives = 0
  [ user-message "Game Over - No Lives Left!" ])

end

to player-score-control

 if player-score = 3
  [ set level-over? true
    user-message "You Win - Mission Complete!" ]

end

to enemy-speed-control

  if color = 15
  [ (ifelse
    shape = "enemy"
    [ set red-speed 0.6 ]
    shape = "enemyflag"
    [ set red-speed 0.8 ])
    ask patch-here
    [ if pcolor = 53
      [ ask enemys-here
        [ if shape = "enemy-flag"
          [ set red-speed 7 ]
        ]
         set red-speed 5
      ]
    ]
  ]

  if color = 45
  [ (ifelse
    shape = "enemy"
    [ set yellow-speed 0.6 ]
    shape = "enemyflag"
    [ set yellow-speed 0.8 ])
    ask patch-here
    [ if pcolor = 53
      [ ask enemys-here
        [ if shape = "enemy-flag"
          [ set yellow-speed 7 ]
        ]
         set yellow-speed 5
      ]
    ]
  ]

  if color = 95
  [ (ifelse
    shape = "enemy"
    [ set blue-speed 0.6 ]
    shape = "enemyflag"
    [ set blue-speed 0.8 ])
    ask patch-here
    [ if pcolor = 53
      [ ask enemys-here
        [ if shape = "enemy-flag"
          [ set blue-speed 7 ]
        ]
         set blue-speed 5
      ]
    ]
  ]

end

to enemy-lives-control

  if red-dead? = true
    [
      if red-lives != 0
      [ set red-lives red-lives - 1
        if red-lives = 0
        [ set all-dead all-dead + 1
          let red-dead (enemys) with [ color = 15 ]
          ask red-dead
          [ die ]
        ]
        set red-dead? false
      ]
    ]

  if yellow-dead? = true
    [
      if yellow-lives != 0
      [ set yellow-lives yellow-lives - 1
        if yellow-lives = 0
        [ set all-dead all-dead + 1
          let yellow-dead (enemys) with [ color = 45 ]
          ask yellow-dead
          [ die ]
        ]
        set yellow-dead? false
      ]
    ]

  if blue-dead? = true
    [
      if blue-lives != 0
      [ set blue-lives blue-lives - 1
        if blue-lives = 0
        [ set all-dead all-dead + 1
          let blue-dead (enemys) with [ color = 95 ]
          ask blue-dead
          [ die ]
        ]
        set blue-dead? false
      ]
    ]

end

to enemy-score-control

  (ifelse
    red-score = 3
    [ set level-over? true
      user-message "Game Over - Red Wins!" ]
    yellow-score = 3
    [ set level-over? true
      user-message "Game Over - Yellow Wins!" ]
    blue-score = 3
    [ set level-over? true
      user-message "Game Over - Blue Wins!" ])

end

;; Move player
to move-player  ;; Observer Procedure

  ask players
  [ player-speed-control

    set heading new-heading

    ;; Player moves forward unless blocked by wall
    if [pcolor] of patch-ahead 1 != gray
    [
      if [pcolor] of patch-here = black or [pcolor] of patch-here = brown
      or [pcolor] of patch-here = cyan ;; Safe Tiles
      [ fd 1 ]

      if [pcolor] of patch-here = orange ;; Lava/Dead
      [ set dead? true
        setxy (item 0 home-pos) (item 1 home-pos)
        if shape = "playerflag"
        [ set shape "player"
          ask flags [ setxy (item 0 home-pos) (item 1 home-pos)
                      set visible? true
                      show-turtle ]
        ]
      ]

      if [pcolor] of patch-here = 53 ;; Marsh
      [ fd 0
        set count-down count-down - 1
        if count-down = 0
        [ fd 1
          set count-down count-down + 10 ;; Reset timer
        ]
      ]
    ]

    ;; If player (flag) walks into enemy
    if any? enemys-here with [ shape = "enemy" ] and shape = "playerflag" ;; WORKS
    [
      ask enemys-here
      [  set shape "enemyflag"
          set flag? true
      ]
      set shape "player"
      set dead? true
      setxy (item 0 home-pos) (item 1 home-pos)
    ]

    ;; Copy from enemy
    ;; If player walks into enemy (flag)
    if any? enemys-here with [ shape = "enemyflag" ] and shape = "player" ;; WORKS
    [
      ask enemys-here
      [
        (ifelse
        color = 15
        [ set red-dead? true ]
        color = 45
        [ set yellow-dead? true ]
        color = 95
        [ set blue-dead? true])

        set shape "enemy"
        set flag? false
        setxy (item 0 home-pos) (item 1 home-pos)
      ]
      set shape "playerflag"
    ]

    ;; If player walks into monster
    if any? monsters-here ;; If player has flag and dies to monster
    [ set dead? true
      if shape = "playerflag"
      [ let flag-drop-pos list xcor ycor
        ask flags [ setxy (item 0 flag-drop-pos) (item 1 flag-drop-pos)
                    set visible? true
                    show-turtle ]
        set shape "player"
      ]
      setxy (item 0 home-pos) (item 1 home-pos)
    ]

    ;; If player walks into flag
    if any? flags-here and visible? = true ;; Pick up flag
    [
      set shape "playerflag"
      ask flags [ hide-turtle
                  set visible? false ]
    ]

    ;; If player walks into home
    if [pxcor] of patch-here = item 0 home-pos and [pycor] of patch-here = item 1 home-pos and shape = "playerflag" ;; Reset if flag is returned to spawn point
    [ set shape "player"
      set player-score player-score + 1
      ask flags [ setxy (item 0 home-pos) (item 1 home-pos)
                  set visible? true
                  show-turtle ]
    ]
  ]

end

;; Move enemy
to move-enemys  ;; Observer Procedure

  ;; Makes swapping enemy to enemy flag easier and more effecient - controls interaction of enemys on same patch
  let nearby-enemy (enemys-on patch-here) with [ flag? = false ]
  let flag-enemy (enemys-on patch-here) with [ flag? = true ]

  ask enemys
  [ enemy-heading
    enemy-speed-control ]



  ;; If enemy walks into lava
  if [pcolor] of patch-here = orange ;; Lava/Dead
  [ ask enemys-here
    [
      (ifelse
      color = 15
        [ set red-dead? true ]
      color = 45
        [ set yellow-dead? true ]
      color = 95
        [ set blue-dead? true ])

      setxy (item 0 home-pos) (item 1 home-pos)
      if shape = "enemyflag"
      [ set shape "enemy"
        set flag? false
        ask flags [ setxy (item 0 home-pos) (item 1 home-pos)
                    set visible? true
                    show-turtle ]
      ]
    ]
  ]

  ;; If enemy (flag) walks into player
  if any? players-here with [ shape = "player" ] and shape = "enemyflag" ;; WORKS
  [
    ask players-here
    [  set shape "playerflag" ]

    (ifelse
    color = 15
      [ set red-dead? true ]
    color = 45
      [ set yellow-dead? true ]
    color = 95
      [ set blue-dead? true ])

    set shape "enemy"
    set flag? false
    setxy (item 0 home-pos) (item 1 home-pos)
  ]

  ;; Copy from player
  ;; If enemy walks into player (flag)
  if any? players-here with [ shape = "playerflag" ] and shape = "enemy" ;; WORKS
  [
    ask players-here
    [ set shape "player"
      set dead? true
      setxy (item 0 home-pos) (item 1 home-pos)
    ]
    set shape "enemyflag"
    set flag? true
  ]

  ;; If enemy (flag) walks into enemy
  if flag? = true
  [
    ask nearby-enemy
    [
      if shape = "enemy"
      [ set shape "enemyflag"
        set flag? true
      ]
      ask flag-enemy
      [
        if shape = "enemyflag"
        [
          (ifelse
            color = 15
            [ set red-dead? true ]
            color = 45
            [ set yellow-dead? true ]
            color = 95
            [ set blue-dead? true ])

          set shape "enemy"
          set flag? false
          setxy (item 0 home-pos) (item 1 home-pos)
        ]
      ]
    ]
  ]

  ;; COPY ABOVE CODE
  ;; If enemy walks into enemy (flag)
  if flag? = false
  [
    ask flag-enemy
    [
      if shape = "enemyflag"
      [
        (ifelse
          color = 15
          [ set red-dead? true ]
          color = 45
          [ set yellow-dead? true ]
          color = 95
          [ set blue-dead? true ])

        set shape "enemy"
        set flag? false
        setxy (item 0 home-pos) (item 1 home-pos)
      ]
      ask nearby-enemy
      [
        if shape = "enemy"
        [ set shape "enemyflag"
          set flag? true
        ]
      ]
    ]
  ]

  ;; If enemy walks into monster
  if any? monsters-here ;; If enemy has flag and dies to monster
  [ ask enemys-here
    [ if shape = "enemyflag"
      [ let flag-drop-pos list xcor ycor
        ask flags [ setxy (item 0 flag-drop-pos) (item 1 flag-drop-pos)
                    set visible? true
                    show-turtle ]
        set shape "enemy"
        set flag? false
      ]
   (ifelse
   color = 15
      [ set red-dead? true ]
   color = 45
      [ set yellow-dead? true ]
   color = 95
      [ set blue-dead? true ])

    setxy (item 0 home-pos) (item 1 home-pos)
    ]
  ]

  ;; If enemy walks into flag
  if any? flags-here and visible? = true ;; Pick up flag
  [
    ask enemys-here
    [ set shape "enemyflag"
      set flag? true ]
      ask flags-here [ hide-turtle
                       set visible? false ]
  ]

  ;; If enemy walks into home
  if [pxcor] of patch-here = item 0 home-pos and [pycor] of patch-here = item 1 home-pos and shape = "enemyflag" ;; Reset if flag is returned to spawn point
  [ ask enemys-here
    [
    (ifelse
      color = 15
        [ set red-score red-score + 1 ]
      color = 45
        [ set yellow-score yellow-score + 1 ]
      color = 95
        [ set blue-score blue-score + 1 ])

      set shape "enemy"
      set flag? false ]
    ask flags [ setxy (item 0 home-pos) (item 1 home-pos)
                set visible? true
                show-turtle ]
  ]

end

;; Enemy direction
to enemy-heading  ;; Monster Procedure
  let dirs enemy-clear-headings
  let new-dirs remove enemy-opposite heading dirs
  let monster-dir false

  if length dirs = 1
  [ set heading item 0 dirs ]
  if length dirs = 2
  [ ifelse see-monster item 0 dirs
    [ set monster-dir item 0 dirs ]
    [ ifelse see-monster item 1 dirs
      [ set monster-dir item 1 dirs ]
      [ set heading one-of new-dirs ]
    ]
  ]
  if length dirs = 3
  [ ifelse see-monster item 0 dirs
    [ set monster-dir item 0 dirs ]
    [ ifelse see-monster item 1 dirs
      [ set monster-dir item 1 dirs ]
      [ ifelse see-monster item 2 dirs
        [ set monster-dir item 2 dirs ]
        [ set heading one-of new-dirs ]
      ]
    ]
  ]
  if length dirs = 4
  [ ifelse see-monster item 0 dirs
    [ set monster-dir item 0 dirs ]
    [ ifelse see-monster item 1 dirs
      [ set monster-dir item 1 dirs ]
      [ ifelse see-monster item 2 dirs
        [ set monster-dir item 2 dirs ]
        [ ifelse see-monster item 3 dirs
          [ set monster-dir item 3 dirs ]
          [ set heading one-of new-dirs ]
        ]
      ]
    ]
  ]
  if monster-dir != false and [pcolor] of patch-ahead 1 != black
  [ set heading enemy-opposite heading ]
end

;; Enemy moving
to-report enemy-clear-headings ;; Enemy procedure
  let dirs []
  if [pcolor] of patch-at 0 1 != gray
  [ set dirs lput 0 dirs ]
  if [pcolor] of patch-at 1 0 != gray
  [ set dirs lput 90 dirs ]
  if [pcolor] of patch-at 0 -1 != gray
  [ set dirs lput 180 dirs ]
  if [pcolor] of patch-at -1 0 != gray
  [ set dirs lput 270 dirs ]
  report dirs
end

to-report enemy-opposite [dir]
  ifelse dir < 180
  [ report dir + 180 ]
  [ report dir - 180 ]
end

;; If nps sees monster
to-report see-monster [dir] ;; Monster procedure
  let saw-monster? false
  let p patch-here
  while [[pcolor] of p = black]
  [ ask p
    [ if any? monsters-here
      [ set saw-monster? true ]
      set p patch-at sin dir cos dir ;; next patch in direction dir
    ]
    ;; stop looking if you loop around the whole world
    if p = patch-here [ report saw-monster? ]
  ]
  report saw-monster?
end

;; Move monster
to move-monsters  ;; Observer Procedure

  ask monsters
    [monsters-heading]

  ;; Monster moves forward on these tiles
  if [pcolor] of patch-ahead 1 = black or [pcolor] of patch-ahead 1 = orange or [pcolor] of patch-ahead 1 = 53
      [ fd 1 ]

  ;; Monster stops before these tiles
  if [pcolor] of patch-ahead 1 = cyan or [pcolor] of patch-ahead 1 = brown ;; Bug fixed - caused contradicting directions
  [
    if [pcolor] of patch-at 0 1 = black
        [ set heading 0 ]
    if [pcolor] of patch-at 1 0 = black
        [ set heading 90 ]
    if [pcolor] of patch-at 0 -1 = black
        [ set heading 180 ]
    if [pcolor] of patch-at -1 0 = black
        [ set heading 270 ]
  ]

  ;; Copy from player
  ;; If monster walks into player
  if any? players-here ;; If player has flag and dies to monster
  [ ask players-here
    [ set dead? true
      if shape = "playerflag"
      [ let flag-drop-pos list xcor ycor
        ask flags [ setxy (item 0 flag-drop-pos) (item 1 flag-drop-pos)
          set visible? true
          show-turtle ]
        set shape "player"
      ]
      setxy (item 0 home-pos) (item 1 home-pos)
    ]
  ]

  ;; Copy from enemy
  ;; If monster walks into enemy
  if any? enemys-here ;; If enemy has flag and dies to monster
  [ ask enemys-here
    [ if shape = "enemyflag"
      [ let flag-drop-pos list xcor ycor
        ask flags [ setxy (item 0 flag-drop-pos) (item 1 flag-drop-pos)
          set visible? true
          show-turtle ]
        set shape "enemy"
        set flag? false
      ]
    (ifelse
      color = 15
      [ set red-dead? true ]
      color = 45
      [ set yellow-dead? true ]
      color = 95
      [ set blue-dead? true ])

    setxy (item 0 home-pos) (item 1 home-pos)
    ]
  ]

end

;; Monster direction based on player
to monsters-heading  ;; Monster Procedure
  let dirs monsters-clear-headings
  let new-dirs remove monster-opposite heading dirs
  let player-dir false
  let enemy-dir false

  if length dirs = 1
  [ set heading item 0 dirs ]
  if length dirs = 2
  [ ifelse see-player item 0 dirs or see-enemy item 0 dirs
    [ set player-dir item 0 dirs set enemy-dir item 0 dirs ]
    [ ifelse see-player item 1 dirs or see-enemy item 1 dirs
      [ set player-dir item 1 dirs set enemy-dir item 1 dirs ]
      [ set heading one-of new-dirs ]
    ]
  ]
  if length dirs = 3
  [ ifelse see-player item 0 dirs or see-enemy item 0 dirs
    [ set player-dir item 0 dirs set enemy-dir item 0 dirs ]
    [ ifelse see-player item 1 dirs or see-enemy item 1 dirs
      [ set player-dir item 1 dirs set enemy-dir item 1 dirs ]
      [ ifelse see-player item 2 dirs or see-enemy item 2 dirs
        [ set player-dir item 2 dirs set enemy-dir item 2 dirs ]
        [ set heading one-of new-dirs ]
      ]
    ]
  ]
  if length dirs = 4
  [ ifelse see-player item 0 dirs or see-enemy item 0 dirs
    [ set player-dir item 0 dirs set enemy-dir item 0 dirs ]
    [ ifelse see-player item 1 dirs or see-enemy item 1 dirs
      [ set player-dir item 1 dirs set enemy-dir item 1 dirs ]
      [ ifelse see-player item 2 dirs or see-enemy item 2 dirs
        [ set player-dir item 2 dirs set enemy-dir item 2 dirs ]
        [ ifelse see-player item 3 dirs or see-enemy item 3 dirs
          [ set player-dir item 3 dirs set enemy-dir item 3 dirs ]
          [ set heading one-of new-dirs ]
        ]
      ]
    ]
  ]
  (ifelse
    player-dir != false
    [ set heading player-dir
      set monster-speed 0.6 ]
    player-dir = false
    [ set monster-speed 1 ])

  (ifelse
    enemy-dir != false
    [ set heading enemy-dir
      set monster-speed 0.6 ]
    enemy-dir = false
    [ set monster-speed 1 ])


  ;;if player-dir != false
  ;;[ set heading player-dir ]
  ;;if enemy-dir != false
  ;;[ set heading enemy-dir ]
end

;; Monster moving
to-report monsters-clear-headings;; Monster procedure
  let dirs []
  if [pcolor] of patch-at 0 1 != gray
  [ set dirs lput 0 dirs ]
  if [pcolor] of patch-at 1 0 != gray
  [ set dirs lput 90 dirs ]
  if [pcolor] of patch-at 0 -1 != gray
  [ set dirs lput 180 dirs ]
  if [pcolor] of patch-at -1 0 != gray
  [ set dirs lput 270 dirs ]


  report dirs
end

to-report monster-opposite [dir]
  ifelse dir < 180
  [ report dir + 180 ]
  [ report dir - 180 ]
end

;; If monster sees player
to-report see-player [dir] ;; Monster procedure
  let saw-player? false
  let p patch-here
  while [[pcolor] of p = black]
  [ ask p
    [ if any? players-here
      [ set saw-player? true ]
      set p patch-at sin dir cos dir ;; next patch in direction dir
    ]
    ;; stop looking if you loop around the whole world
    if p = patch-here [ report saw-player? ]
  ]
  report saw-player?
end

;; If monster sees npc
to-report see-enemy [dir] ;; Monster procedure
  let saw-enemy? false
  let p patch-here
  while [[pcolor] of p = black]
  [ ask p
    [ if any? enemys-here
      [ set saw-enemy? true ]
      set p patch-at sin dir cos dir ;; next patch in direction dir
    ]
    ;; stop looking if you loop around the whole world
    if p = patch-here [ report saw-enemy? ]
  ]
  report saw-enemy?
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Interface Procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to move-up
  ask players [ set new-heading 0 ]
end

to move-right
  ask players [ set new-heading 90 ]
end

to move-down
  ask players [ set new-heading 180 ]
end

to move-left
  ask players [ set new-heading 270 ]
end
@#$#@#$#@
GRAPHICS-WINDOW
243
10
1064
832
-1
-1
38.7143
1
10
1
1
1
0
1
1
1
-10
10
-10
10
1
1
0
ticks
30.0

BUTTON
14
157
124
190
New
new
NIL
1
T
OBSERVER
NIL
N
NIL
NIL
1

BUTTON
124
157
234
190
Play
play
T
1
T
OBSERVER
NIL
P
NIL
NIL
0

BUTTON
91
247
146
280
Up
move-up
NIL
1
T
TURTLE
NIL
W
NIL
NIL
0

BUTTON
146
280
201
313
Right
move-right
NIL
1
T
TURTLE
NIL
D
NIL
NIL
0

BUTTON
91
280
146
313
Down
move-down
NIL
1
T
TURTLE
NIL
S
NIL
NIL
0

BUTTON
36
280
91
313
Left
move-left
NIL
1
T
TURTLE
NIL
A
NIL
NIL
0

MONITOR
14
110
69
155
Level
level
0
1
11

MONITOR
161
787
243
832
Player Lives
player-lives
0
1
11

MONITOR
161
54
243
99
Red Lives
red-lives
0
1
11

MONITOR
1063
54
1145
99
Yellow Lives
yellow-lives
0
1
11

MONITOR
1063
787
1145
832
Blue Lives
blue-lives
0
1
11

MONITOR
161
10
243
55
Red Score
red-score
0
1
11

MONITOR
1063
10
1145
55
Yellow Score
yellow-score
0
1
11

MONITOR
1063
743
1145
788
Blue Score
blue-score
0
1
11

MONITOR
161
743
243
788
Player Score
player-score
0
1
11

@#$#@#$#@
## WHAT IS IT?

This is the classic arcade game, Pac-Man.  The game involves navigating Pac-Man through a maze.  Your objective is that Pac-Man eat all of the pellets (white circles), while avoiding the ghosts that pursue him.

If a ghost ever catches Pac-Man then Pac-Man is defeated.  If this occurs, the level will reset, but this will happen only if Pac-Man still has some lives remaining. (The pellets already collected on the level remain collected.)

However, when Pac-Man eats a Power-Pellet (large white circle) he can turn the tide, and the ghosts will turn scared and flee from him, for with the power of the Power-Pellet, Pac-Man can eat the ghosts!  Once a ghost is eaten it will return to its base, where it is born again, immune to the Power-Pellet until Pac-Man can find a new one to consume.  Pac-Man had better do just that, because unfortunately, the power of the Power-Pellet does not last forever, and will begin to wear off over time. (You will see the ghosts start to flash back to their normal appearance during the last few seconds of the Power-Pellet's effectiveness.)

Finally, occasionally a bonus (rotating star) will appear in the maze.  This bonus gives Pac-Man extra points if he eats it, but it will disappear if Pac-Man doesn't get it within a limited amount of time.

## HOW TO USE IT

Monitors
-- SCORE shows your current score.  You get points for collecting pellets, eating ghosts, and collecting bonuses.  You will get an extra life after every 35,000 points.
-- LEVEL shows your current level.  Each level has a different map, if you complete all the maps, it will loop back to the first map and continue.
-- LIVES shows how many extra lives you have remaining.  If you are defeated by a ghost when this is at 0, the game is over.

Sliders
-- DIFFICULTY controls the speed of the game.  Lower numbers make both the ghosts and Pac-Man move slowly, giving you more time to react as you play.

Buttons
-- NEW sets up a new game on level 1, with 3 lives, and a score of 0.
-- PLAY begins the game.  The game will pause after each level, so you will need to hit PLAY again after each level to continue.

Controls
-- UP, DOWN, LEFT, RIGHT control the direction Pac-Man moves.

## THINGS TO NOTICE

If you go off the edge of the maze you will wrap around to the other side.

Identifying Things in the Maze:
-- Yellow Circle with a mouth:  This is Pac-Man - you.
-- White Circles:
               These are Pellets - Collect all of these (including the Power-Pellets) to move on to the next level.

-- Large White Circles:
         These are Power-Pellets - They allow you to eat the Ghosts for a limited ammount of time.

-- Blue Squares:
                These are the walls of the maze - Neither Pac-Man nor the Ghosts can move through the walls.

-- Gray Squares:
                These are the Ghost Gates - Only Ghosts can move through them, and if they do so after having been eaten they will be healed.

-- Rotating Colored Stars:
      These are Bonus Stars - They give you extra points when you eat them.

-- Colorful Ghost with Eyes:
    These are the active Ghosts - Watch out for them!

-- Blue Ghost Shape:
            These are the scared Ghosts - Eat them for Extra Points!

-- Two Small Eyes:
              These are the Ghosts after they've been eaten - They will not affect you, and you can't eat them again, so just ignore them, but try not to be near its base when it gets back there.

Scoring System
-- Eat a Pellet:
       100 Points

-- Eat a Power-Pellet: 500 Points
-- Eat a Scared Ghost: 500 Points
-- Eat a Bonus Star:   100-1000 Points (varies)

## THINGS TO TRY

Beat your Highest Score.

Can you write an automated program for Pac-Man that will get him safely through the maze and collect all the pellets?

## EXTENDING THE MODEL

Think of other power-ups or bonuses that might be fun to have and make them appear randomly in the maze.

Add new enemies that behave differently from the ghosts.

## NETLOGO FEATURES

This model makes use of breeds, create-<breed>, every, and user-message.

The "import-world" command is used to read in the different maze configurations (levels).

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Wilensky, U. (2001).  NetLogo Pac-Man model.  http://ccl.northwestern.edu/netlogo/models/Pac-Man.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2001 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227.

<!-- 2001 -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 45 45 210

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

enemy
false
0
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90

enemyflag
false
0
Polygon -7500403 true true 120 90 225 75 210 105 135 120
Line -1184463 false 165 105 165 135
Line -1184463 false 240 60 240 90
Rectangle -7500403 true true 82 79 127 94
Circle -7500403 true true 65 5 80
Polygon -7500403 true true 60 90 75 195 45 285 60 300 90 300 105 225 120 300 150 300 165 285 135 195 150 90
Rectangle -6459832 true false 165 255 225 255
Polygon -6459832 true false 0 165 0 180 270 60 270 45
Polygon -7500403 true true 60 90 15 150 30 180 90 105
Polygon -8630108 true false 255 75 150 120 195 300 255 75

eyes
false
0
Circle -1 true false 62 75 57
Circle -1 true false 182 75 57
Circle -16777216 true false 79 93 20
Circle -16777216 true false 196 93 21

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -6459832 true false 60 15 75 300
Polygon -8630108 true false 90 150 270 90 90 30
Line -1184463 false 75 135 90 135
Line -1184463 false 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

ghost
false
0
Circle -7500403 true true 61 30 179
Rectangle -7500403 true true 60 120 240 232
Polygon -7500403 true true 60 229 60 284 105 239 149 284 195 240 239 285 239 228 60 229
Circle -1 true false 81 78 56
Circle -16777216 true false 99 98 19
Circle -1 true false 155 80 56
Circle -16777216 true false 171 98 17

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

monster
false
0
Circle -6459832 true false 15 30 270
Circle -1 true false 30 15 90
Circle -1 true false 150 120 0
Rectangle -16777216 true false 120 195 180 210
Polygon -1 true false 165 195 195 195 180 285 165 195 135 195 120 285 105 195
Circle -1 true false 180 15 90
Circle -16777216 true false 60 60 30
Circle -16777216 true false 210 60 30

pacman
true
0
Circle -7500403 true true 0 0 300
Polygon -16777216 true false 105 -15 150 150 195 -15

pacman open
true
0
Circle -7500403 true true 0 0 300
Polygon -16777216 true false 270 -15 149 152 30 -15

pellet
true
0
Circle -7500403 true true 105 105 92

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

player
false
4
Rectangle -13840069 true false 127 79 172 94
Polygon -13840069 true false 195 90 240 150 225 180 165 105
Polygon -13840069 true false 105 90 60 150 75 180 135 105
Circle -13840069 true false 110 5 80
Polygon -13840069 true false 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90

playerflag
false
0
Polygon -13840069 true false 120 90 225 75 210 105 135 120
Line -1184463 false 165 105 165 135
Line -1184463 false 240 60 240 90
Rectangle -13840069 true false 82 79 127 94
Circle -13840069 true false 65 5 80
Polygon -13840069 true false 60 90 75 195 45 285 60 300 90 300 105 225 120 300 150 300 165 285 135 195 150 90
Rectangle -6459832 true false 165 255 225 255
Polygon -6459832 true false 0 165 0 180 270 60 270 45
Polygon -13840069 true false 60 90 15 150 30 180 90 105
Polygon -8630108 true false 255 75 150 120 195 300 255 75

scared
false
0
Circle -13345367 true false 61 30 179
Rectangle -13345367 true false 60 120 240 232
Polygon -13345367 true false 60 229 60 284 105 239 149 284 195 240 239 285 239 228 60 229
Circle -16777216 true false 81 78 56
Circle -16777216 true false 155 80 56
Line -16777216 false 137 193 102 166
Line -16777216 false 103 166 75 194
Line -16777216 false 138 193 171 165
Line -16777216 false 172 166 198 192

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
new
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@

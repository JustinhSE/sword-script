
#!/bin/bash

# --- DEPENDENCY CHECKS ---
check_dependencies() {
    local missing=()
    command -v jq >/dev/null 2>&1 || missing+=("jq")
    command -v cowsay >/dev/null 2>&1 || missing+=("cowsay")
    command -v lolcat >/dev/null 2>&1 || missing+=("lolcat")
    command -v curl >/dev/null 2>&1 || missing+=("curl")
    command -v bc >/dev/null 2>&1 || missing+=("bc")
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo "❌ Missing dependencies: ${missing[*]}"
        echo "Install with: sudo apt install ${missing[*]} (or brew on macOS)"
        exit 1
    fi
    
    if ! python3 -c "import rapidfuzz" 2>/dev/null; then
        echo "⚠️  Installing rapidfuzz Python library..."
        pip3 install rapidfuzz --user || {
            echo "❌ Failed to install rapidfuzz. Install manually: pip3 install rapidfuzz"
            exit 1
        }
    fi
}

check_dependencies

# --- CONFIGURATION ---
VERSION="niv"
CATEGORY="random"
PROGRESS_FILE="$HOME/.bible_progress"
MASTERY_LEVEL=4
touch "$PROGRESS_FILE"

# --- 1. RANDOM SWORD SELECTOR ---
clear
DRAW_SWORD=$(( ( RANDOM % 5 ) + 1 ))

display_logo() {
case $DRAW_SWORD in
1) cat << 'EOF'
          +++
          ++++
          ++ ++
           ++ ++
            ++ ++
             ++ ++
              ++ ++
               ++ ++
                ++ ++
                 ++ ++             *
                  ++ ++            **
                   ++ ++            **
                    ++ ++           ***
                     ++ ++           ***
                      ++ ++          ***
                       ++ ++        ****
                        ++ ++      ****
                         ++ ++    ****
                          ++ ++  ****
                           ++ ++****
                            +++****
                             +****
                             ****%%
                            ****%%%%
                           **** %%%%
                  * **** %%%%
                   ** **** %%%%
                    *** **** %%%%
                     ****** %%%%
                      **** %%%%
                                       %%%$$$
                                        %$$$$$
                                        $$$$$$$
                                        $$$$$$$
                                         $$$$$
                                          $$$
EOF
;;
2) cat << 'EOF'
                    / \
                   / | \
                  /  |  \
                 |   |   |
                 |   |   |
                 |   |   |
                 |   |   |
                 |   |   |
                 |   |   |
                 |   |   |
                 |   |   |
                 |   |   |
                 |   |   |
                 |   |   |
                 |   |   |
                 |   |   |
                 |   |   |
                 |   |   |
                 |   |   |
                 |   |   |
/\               |/     \|               /\
\ \_____________/         \_____________/ /
 \______________\         /______________/
                 \       /
                 |\\   //|
                 |//\ ///|
                 |///////|
                 |///////|
                / \/\_/\/ \
               |\_/\/ \/\_/|
                \_/\/_\/\_/
                  \_/_\_/
EOF
;;
3) cat << 'EOF'
                                ,-.
                               ("O_)
                              / `-/
                             /-. /
                            /   )
                           /   /  
              _           /-. /
             (_)"-._     /   )
               "-._ "-'""( )/    
                   "-/"-._" `. 
                    /     "-.'._
                   /\       /-._"-._
    _,---...__    /  ) _,-"/    "-(_)
___<__(|) _   ""-/  / /   /
 '  `----' ""-.   \/ /   /
               )  ] /   /
       ____..-'   //   /                       )
   ,-""      __.,'/   /   ___                 /,
  /    ,--""/  / /   /,-""   ___-.          ,'/
 [    (    /  / /   /  ,.---,_   `._   _,-','
  \    `-./  / /   /  /       `-._  """ ,-'
   `-._  /  / /   /_,'            ""--"
       "/  / /   /"         
EOF
;;
4) cat << 'EOF'
          /\
         /::\
        | :: |
        | :: |                     />>>
        | :: |                    (*>
        | :: |           ()%\%\%\%|*|33333333333333333333333333333333>
        | :: |                    (*>
        | :: |                     \>>>
        | :: |
        | :: |                    []
        | :: |                    oo //
        | :: |           ()%\%\%\%||::================================-
        | :: |                    oo \\
        | :: |                    []
1       | :: |       1
8b      | :: |      d8
88b   ,%| :: |%,   d88
888b%%%%| :: |%%%%d888
 "Y88888[[[]]]88888Y"
        [[[]]]
EOF
;;
5) cat << 'EOF'
            |
            |\
8*<%%%%%%%%%|+>-===================================================-----
            |/
            |
EOF
;;
esac
}

display_logo | lolcat

# --- 2. THE FIXED BORDERED QUOTE ---
echo -e "\033[1;37m"
echo " ╔═══════════════════════════════════════════════════════════════════╗"
echo " ║ For the word of God is alive and active. Sharper than any         ║"
echo " ║ double-edged sword, it penetrates even to dividing soul and       ║"
echo " ║ spirit, joints and marrow; it judges the thoughts and             ║"
echo " ║ attitudes of the heart.                        - Hebrews 4:12     ║"
echo " ╚═══════════════════════════════════════════════════════════════════╝"
echo -e "\033[0m"

# --- 2. SELECTION LOGIC ---
ROLL=$(( ( RANDOM % 100 ) + 1 ))
REVIEW_COUNT=$(grep -v "|$MASTERY_LEVEL$" "$PROGRESS_FILE" 2>/dev/null | wc -l | xargs)

if [ "$REVIEW_COUNT" -gt 0 ] && [ "$ROLL" -le 70 ]; then
    MODE="REVIEW"
    ENTRY=$(grep -v "|$MASTERY_LEVEL$" "$PROGRESS_FILE" | shuf -n 1)
    REFERENCE=$(echo "$ENTRY" | cut -d'|' -f1)
    CURRENT_LEVEL=$(echo "$ENTRY" | cut -d'|' -f2)
    URL_REF=$(echo "$REFERENCE" | jq -sRr @uri)
    DATA=$(curl -s "https://bible-api.com/$URL_REF?translation=$VERSION")
else
    MODE="NEW"
    DATA=$(curl -s "https://bible-api.com/data/$VERSION/random")
    REFERENCE=$(echo "$DATA" | jq -r '.reference // empty')
    CURRENT_LEVEL=$(grep "^$REFERENCE|" "$PROGRESS_FILE" 2>/dev/null | cut -d'|' -f2)
    : ${CURRENT_LEVEL:=1}
fi

# CRITICAL FIX: Ensure variables are never "null"
VERSE_TEXT=$(echo "$DATA" | jq -r '.text // empty' | tr -d '\n' | sed 's/  */ /g')
REFERENCE=$(echo "$DATA" | jq -r '.reference // empty')

if [[ -z "$VERSE_TEXT" || "$VERSE_TEXT" == "null" ]]; then
    REFERENCE="Psalm 119:105"
    VERSE_TEXT="Thy word is a lamp unto my feet, and a light unto my path."
    CURRENT_LEVEL=1
    MODE="OFFLINE/FAILSAFE"
fi

# --- 3. CHALLENGE DISPLAY ---
printf "\033[1;35m[%s MODE] -- Level %s\033[0m\n" "$MODE" "$CURRENT_LEVEL"
printf "\033[1;37mRef: %s\033[0m\n" "$REFERENCE"

generate_skeleton() {
    echo "$VERSE_TEXT" | awk '{
        for(i=1;i<=NF;i++) {
            printf substr($i,1,1);
            for(j=2;j<=length($i);j++) printf "_";
            printf " "
        }
        print ""
    }'
}

case $CURRENT_LEVEL in
    1) echo "$VERSE_TEXT" | cowsay -f tux -W 50 | lolcat ;;
    2) generate_skeleton | cowsay -f tux -W 50 | lolcat ;;
    3) echo "???" | cowsay -f tux -W 50 | lolcat ;;
esac

# --- 4. INPUT LOOP ---
printf "\n\033[1;33m⚔️  Type the verse or 'skip':\033[0m\n"

while true; do
    read -p "> " USER_INPUT
    [[ "$USER_INPUT" == "quit" || "$USER_INPUT" == "skip" ]] && exit 0

    CLEAN_TEXT=$(echo "$VERSE_TEXT" | tr -d '[:punct:]' | tr '[:upper:]' '[:lower:]' | xargs)
    CLEAN_INPUT=$(echo "$USER_INPUT" | tr -d '[:punct:]' | tr '[:upper:]' '[:lower:]' | xargs)

    SIMILARITY=$(python3 <<EOF
from rapidfuzz import fuzz
print(fuzz.ratio("""$CLEAN_TEXT""", """$CLEAN_INPUT"""))
EOF
)

    if [ $(echo "$SIMILARITY > 85" | bc) -ne 0 ]; then
        printf "\033[1;32m✨ STRIKE! Correct (%s%% match)\033[0m\n" "$SIMILARITY"
        NEW_LEVEL=$((CURRENT_LEVEL + 1))
        [ $NEW_LEVEL -gt $MASTERY_LEVEL ] && NEW_LEVEL=$MASTERY_LEVEL
        grep -v "^$REFERENCE|" "$PROGRESS_FILE" 2>/dev/null > "${PROGRESS_FILE}.tmp"
        echo "$REFERENCE|$NEW_LEVEL" >> "${PROGRESS_FILE}.tmp"
        mv "${PROGRESS_FILE}.tmp" "$PROGRESS_FILE"
        break
    else
        printf "\033[1;31m❌ Parry! Try again (%s%%). Hint: 'skip'\033[0m\n" "$SIMILARITY"
    fi
done




























































































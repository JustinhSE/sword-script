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

# --- 3. SELECTION LOGIC (70% Review / 30% New) ---
ROLL=$(( ( RANDOM % 100 ) + 1 ))
REVIEW_COUNT=$(grep -v "|$MASTERY_LEVEL$" "$PROGRESS_FILE" 2>/dev/null | wc -l | xargs)

if [ "$REVIEW_COUNT" -gt 0 ] && [ "$ROLL" -le 70 ]; then
    MODE="REVIEW"
    ENTRY=$(grep -v "|$MASTERY_LEVEL$" "$PROGRESS_FILE" | shuf -n 1)
    REFERENCE=$(echo "$ENTRY" | cut -d'|' -f1)
    CURRENT_LEVEL=$(echo "$ENTRY" | cut -d'|' -f2)
    URL_REF=$(echo "$REFERENCE" | jq -sRr @uri)
    DATA=$(curl -s "https://bible-api.com/$URL_REF?translation=$VERSION")
    
    if [ -z "$DATA" ] || [ "$DATA" == "null" ]; then
        echo "❌ API error. Using NEW mode fallback..."
        MODE="NEW"
        DATA=$(curl -s "https://bible-api.com/data/$VERSION/random/$CATEGORY")
    fi
else
    MODE="NEW"
    DATA=$(curl -s "https://bible-api.com/data/$VERSION/random/$CATEGORY")
fi

VERSE_TEXT=$(echo "$DATA" | jq -r '.text' | tr -d '\n' | sed 's/  */ /g')
REFERENCE=$(echo "$DATA" | jq -r '.reference')

if [[ "$MODE" == "NEW" ]]; then
    CURRENT_LEVEL=$(grep "^$REFERENCE|" "$PROGRESS_FILE" 2>/dev/null | cut -d'|' -f2)
    : ${CURRENT_LEVEL:=1}
fi

# --- 4. DISPLAY CHALLENGE ---
echo -e "\033[1;35m[$MODE MODE] -- Level $CURRENT_LEVEL\033[0m"
echo -e "\033[1;37mRef: $REFERENCE\033[0m"

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

# --- 5. INTERACTIVE LOOP ---
echo -e "\n\033[1;33m⚔️  Draw your Sword (Type the verse) or 'skip':\033[0m"

ATTEMPT=0
while true; do
    read -p "> " USER_INPUT
    [[ "$USER_INPUT" == "quit" || "$USER_INPUT" == "skip" ]] && exit 0

    CLEAN_TEXT=$(echo "$VERSE_TEXT" | tr -d '[:punct:]' | tr '[:upper:]' '[:lower:]' | xargs)
    CLEAN_INPUT=$(echo "$USER_INPUT" | tr -d '[:punct:]' | tr '[:upper:]' '[:lower:]' | xargs)

    SIMILARITY=$(python3 <<EOF
from rapidfuzz import fuzz
text = """$CLEAN_TEXT"""
user = """$CLEAN_INPUT"""
print(fuzz.ratio(text, user))
EOF
)

    if [ $(echo "$SIMILARITY > 85" | bc) -ne 0 ]; then
        echo -e "\033[1;32m✨ STRIKE! Correct ($SIMILARITY% match)\033[0m"
        NEW_LEVEL=$((CURRENT_LEVEL + 1))
        [ $NEW_LEVEL -gt $MASTERY_LEVEL ] && NEW_LEVEL=$MASTERY_LEVEL
        grep -v "^$REFERENCE|" "$PROGRESS_FILE" 2>/dev/null > "${PROGRESS_FILE}.tmp"
        echo "$REFERENCE|$NEW_LEVEL" >> "${PROGRESS_FILE}.tmp"
        mv "${PROGRESS_FILE}.tmp" "$PROGRESS_FILE"
        echo -e "\033[1;36mLevel Up -> Now Level $NEW_LEVEL\033[0m"
        break
    else
        ATTEMPT=$((ATTEMPT + 1))
        echo -e "\033[1;31m❌ Parry! Try again ($SIMILARITY%). Hint: 'skip'\033[0m"
        
        if [ "$CURRENT_LEVEL" -eq 3 ] && [ "$ATTEMPT" -ge 2 ]; then
            echo -e "\033[1;33m💡 Hint: $(generate_skeleton)\033[0m"
        fi
        
        if [ "$ATTEMPT" -ge 3 ]; then
            echo -e "\033[1;30mReveal: $VERSE_TEXT\033[0m"
        fi
    fi
done

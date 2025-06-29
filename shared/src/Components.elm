module Components exposing (IconType(..), footer, icon, link, logo, logoButton, sideBar, stringToIconType, textLink)

import API
import Html exposing (Html)
import Html.Attributes exposing (style)


logo : Html msg
logo =
    Html.img
        [ Html.Attributes.title "Profile Peek"
        , Html.Attributes.src (API.assetUrl ++ "/icons/logo.svg")
        , Html.Attributes.width 200
        , Html.Attributes.height 30
        ]
        []


logoButton : Html msg
logoButton =
    icon (Just ProfilePeek) 40 40


column : List (Html msg) -> Html msg
column children =
    Html.div
        [ style "display" "flex"
        , style "flex-direction" "column"
        , style "align-items" "center"
        , style "justify-content" "center"
        , style "width" "100%"
        , style "height" "100%"
        , style "gap" "15px"
        , style "padding-bottom" "10px"
        ]
        children


sideBar : List (Html msg) -> Html msg
sideBar children =
    Html.div
        [ style "position" "fixed"
        , style "top" "50%"
        , style "transorms" "translateY(-50%)"
        , style "left" "10px"
        , style "background-color" "black"
        , style "padding" "4px"
        , style "border-radius" "100px"
        , style "border" "1px solid grey"
        ]
        [ column children ]


link : String -> Html msg -> Html msg
link url children =
    Html.a
        [ Html.Attributes.href url
        , style "display" "inline-flex"
        , style "align-items" "center"
        , style "justify-content" "center"
        , style "padding" "0"
        , style "margin" "0"
        , style "text-decoration" "none"
        , style "line-height" "1"
        , Html.Attributes.target "_blank"
        , Html.Attributes.rel "noopener noreferrer"
        ]
        [ children ]


type IconType
    = Steam
    | Leetify
    | CsStats
    | ProfilePeek
    | Faceitfinder
    | X
    | Mail
    | Extension
    | Faceit
    | Level1
    | Level2
    | Level3
    | Level4
    | Level5
    | Level6
    | Level7
    | Level8
    | Level9
    | Level10


icon : Maybe IconType -> Int -> Int -> Html msg
icon maybeIconType width height =
    case maybeIconType of
        Just iconType ->
            Html.img
                [ Html.Attributes.title (iconTypeToString iconType)
                , Html.Attributes.class "profile-peek-icon"
                , Html.Attributes.src (iconMapping iconType)
                , Html.Attributes.width width
                , Html.Attributes.height height
                , Html.Attributes.style "transition" "all 0.3s ease-in-out"
                ]
                []

        Nothing ->
            Html.text ""


iconMapping : IconType -> String
iconMapping iconType =
    case iconType of
        Steam ->
            API.assetUrl ++ "/icons/steam.svg"

        Leetify ->
            API.assetUrl ++ "/icons/leetify.svg"

        CsStats ->
            API.assetUrl ++ "/icons/csstats.svg"

        ProfilePeek ->
            API.assetUrl ++ "/icons/logo-button.svg"

        Faceitfinder ->
            API.assetUrl ++ "/icons/faceitfinder.svg"

        X ->
            API.assetUrl ++ "/icons/x.svg"

        Mail ->
            API.assetUrl ++ "/icons/mail.svg"

        Extension ->
            API.assetUrl ++ "/icons/extension.svg"

        Faceit ->
            API.assetUrl ++ "/icons/faceit.svg"

        Level1 ->
            API.assetUrl ++ "/icons/faceit/level1.svg"

        Level2 ->
            API.assetUrl ++ "/icons/faceit/level2.svg"

        Level3 ->
            API.assetUrl ++ "/icons/faceit/level3.svg"

        Level4 ->
            API.assetUrl ++ "/icons/faceit/level4.svg"

        Level5 ->
            API.assetUrl ++ "/icons/faceit/level5.svg"

        Level6 ->
            API.assetUrl ++ "/icons/faceit/level6.svg"

        Level7 ->
            API.assetUrl ++ "/icons/faceit/level7.svg"

        Level8 ->
            API.assetUrl ++ "/icons/faceit/level8.svg"

        Level9 ->
            API.assetUrl ++ "/icons/faceit/level9.svg"

        Level10 ->
            API.assetUrl ++ "/icons/faceit/level10.svg"


stringToIconType : String -> Maybe IconType
stringToIconType str =
    case str of
        "Steam" ->
            Just Steam

        "Leetify" ->
            Just Leetify

        "CsStats" ->
            Just CsStats

        "ProfilePeek" ->
            Just ProfilePeek

        "Faceitfinder" ->
            Just Faceitfinder

        "Faceit" ->
            Just Faceit

        "Level1" ->
            Just Level1

        "Level2" ->
            Just Level2

        "Level3" ->
            Just Level3

        "Level4" ->
            Just Level4

        "Level5" ->
            Just Level5

        "Level6" ->
            Just Level6

        "Level7" ->
            Just Level7

        "Level8" ->
            Just Level8

        "Level9" ->
            Just Level9

        "Level10" ->
            Just Level10

        _ ->
            Nothing


iconTypeToString : IconType -> String
iconTypeToString iconType =
    case iconType of
        Steam ->
            "Steam"

        Leetify ->
            "Leetify"

        CsStats ->
            "csstats"

        ProfilePeek ->
            "ProfilePeek"

        Faceitfinder ->
            "Faceitfinder"

        X ->
            "X"

        Mail ->
            "Mail"

        Extension ->
            "Extension"

        Faceit ->
            "Faceit"

        Level1 ->
            "Level1"

        Level2 ->
            "Level2"

        Level3 ->
            "Level3"

        Level4 ->
            "Level4"

        Level5 ->
            "Level5"

        Level6 ->
            "Level6"

        Level7 ->
            "Level7"

        Level8 ->
            "Level8"

        Level9 ->
            "Level9"

        Level10 ->
            "Level10"


textLink : String -> String -> Html msg
textLink url text =
    Html.a
        [ Html.Attributes.href url
        , Html.Attributes.target "_blank"
        , style "color" "white"
        , style "text-decoration" "underline"
        ]
        [ Html.text text ]


footer : Html msg
footer =
    Html.footer
        [ style "background-color" "rgb(34, 32, 32)"
        , style "width" "100%"
        , style "position" "fixed"
        , style "bottom" "0"
        , style "display" "flex"
        , style "align-items" "center"
        , style "justify-content" "center"
        , style "padding" "20px"
        , style "gap" "10px"
        ]
        [ link "https://chromewebstore.google.com/detail/profile-peek/fbpcaneckpeeinnachahnnpapdiaohei" <| icon (Just Extension) 30 30
        , link "https://steamcommunity.com/groups/profile-peek" <| icon (Just Steam) 20 20
        , link "https://x.com/ProfilePeek" <| icon (Just X) 20 20
        , link "mailto:hi@profile-peek.com" <| icon (Just Mail) 30 30
        ]

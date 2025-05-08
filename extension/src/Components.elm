module Components exposing (IconType(..), icon, link, logo, sideBar, stringToIconType)

import API exposing (assetUrl)
import Html exposing (Html)
import Html.Attributes exposing (style)


logo : Html msg
logo =
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
    = Leetify
    | CsStats
    | ProfilePeek


icon : Maybe IconType -> Int -> Int -> Html msg
icon maybeIconType width heigth =
    case maybeIconType of
        Just iconType ->
            Html.img [ Html.Attributes.title (iconTypeToString iconType), Html.Attributes.src (iconMapping iconType), Html.Attributes.width width, Html.Attributes.height heigth ] []

        Nothing ->
            Html.text ""


iconMapping : IconType -> String
iconMapping iconType =
    case iconType of
        Leetify ->
            assetUrl ++ "/icons/leetify.svg"

        CsStats ->
            assetUrl ++ "/icons/csstats.svg"

        ProfilePeek ->
            assetUrl ++ "/icons/logo-button.svg"


stringToIconType : String -> Maybe IconType
stringToIconType str =
    case str of
        "Leetify" ->
            Just Leetify

        "CsStats" ->
            Just CsStats

        "ProfilePeek" ->
            Just ProfilePeek

        _ ->
            Nothing


iconTypeToString : IconType -> String
iconTypeToString iconType =
    case iconType of
        Leetify ->
            "Leetify"

        CsStats ->
            "csstats"

        ProfilePeek ->
            "ProfilePeek"

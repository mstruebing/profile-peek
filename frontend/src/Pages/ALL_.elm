module Pages.ALL_ exposing (Model, Msg, page)

import API exposing (Response, Site, responseDecoder)
import Components exposing (footer)
import Effect exposing (Effect)
import Html exposing (Html)
import Html.Attributes exposing (autofocus, disabled, placeholder, style, value)
import Html.Events exposing (onInput, onSubmit)
import Http exposing (Error(..))
import Page exposing (Page)
import RemoteData exposing (RemoteData)
import Route exposing (Route)
import Route.Path as Path
import Shared
import Url exposing (percentEncode)
import View exposing (View)


page : Shared.Model -> Route { all_ : List String } -> Page Model Msg
page _ route =
    Page.new
        { init = init route
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- INIT


type alias Model =
    { response : RemoteData Http.Error Response
    , input : String
    }


init : Route { all_ : List String } -> () -> ( Model, Effect Msg )
init route () =
    ( { response = RemoteData.Loading, input = routeToPlayerUrl route }
    , Effect.sendCmd <|
        getPlayerEffect (routeToPlayerUrl route)
    )


getPlayerEffect : String -> Cmd Msg
getPlayerEffect route =
    Http.get
        { url = API.playerUrl ++ "/" ++ percentEncode route
        , expect = Http.expectJson GotResult responseDecoder
        }


routeToPlayerUrl : Route { all_ : List String } -> String
routeToPlayerUrl route =
    String.slice 1 (String.length route.url.path) route.url.path



-- UPDATE


type Msg
    = NoOp
    | UpdateInput String
    | Submit
    | GotResult (Result Http.Error API.Response)


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        NoOp ->
            ( model
            , Effect.none
            )

        UpdateInput input ->
            ( { model | input = input }, Effect.none )

        Submit ->
            ( { model | response = RemoteData.Loading }
            , Effect.batch
                [ Effect.sendCmd <| getPlayerEffect model.input
                , Effect.pushRoutePath <| Path.ALL_ { all_ = [ model.input ] }
                ]
            )

        GotResult (Ok response) ->
            ( { model | response = RemoteData.Success response }, Effect.none )

        GotResult (Err error) ->
            ( { model | response = RemoteData.Failure error }, Effect.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title = "Profile-Peek - Easy Access to Player Profiles Across Platforms"
    , body =
        [ header
        , Html.div
            [ Html.Attributes.id "wrapper"
            , style "display" "flex"
            , style "flex-direction" "column"
            , style "justify-content" "space-between"
            , style "gap" "50px"
            , style "padding-top"
                (if model.response == RemoteData.NotAsked then
                    "40vh"

                 else
                    "20vh"
                )
            , style "height"
                (if model.response == RemoteData.NotAsked then
                    "auto"

                 else
                    "40vh"
                )
            ]
            [ searchBox model, searchResults model ]
        , footer
        ]
    }


header : Html Msg
header =
    Html.header
        [ style "background-color" "rgb(34, 32, 32)"
        , style "width" "100%"
        , style "position" "fixed"
        , style "top" "10px"
        , style "display" "flex"
        , style "align-items" "center"
        , style "justify-content" "space-between"
        , style "padding" "20px"
        ]
        [ Html.a [ Html.Attributes.href "/" ] [ Components.logo ]
        , buyMeACoffee
        ]


searchBox : Model -> Html Msg
searchBox model =
    Html.div
        [ style "display" "flex"
        , style "flex-direction" "column"
        , style "align-items" "center"
        , style "justify-content" "center"
        ]
        [ Html.form
            [ onSubmit Submit
            , style "width" "100%"
            ]
            [ Html.div
                [ style "display" "flex"
                , style "align-items" "center"
                , style "justify-content" "center"
                , style "flex-direction" "column"
                , style "gap" "10px"
                , style "width" "90%"
                , style "margin" "0 auto"
                ]
                [ Html.input
                    [ placeholder "Enter the Steam Profile URL"
                    , Html.Attributes.name "steam profile url"
                    , autofocus True
                    , onInput UpdateInput
                    , value model.input
                    , style "max-width" "500px"
                    , style "width" "100%"
                    , style "height" "40px"
                    , style "line-height" "35px"
                    , style "font-size" "16px"
                    , style "border-radius" "22px"
                    , style "padding" "5px 12px"
                    , style "background-color" "white"
                    ]
                    []
                , Html.div [ style "height" "45px" ]
                    [ Html.button
                        [ disabled <|
                            String.isEmpty model.input
                                || (model.response == RemoteData.Loading)
                        , style "background-color" "#123"
                        , style "margin" "5px"
                        , style "color" "white"
                        , style "border-radius" "22px"
                        , style "border-style" "solid"
                        , style "border-color" "white"
                        , style "padding" "0 0 0 6px"
                        , Html.Attributes.id "submit-button"
                        ]
                        [ Html.div
                            [ style "display" "flex"
                            , style "align-items" "center"
                            , style "justify-content" "center"
                            , style "gap" "10px"
                            ]
                            [ Html.text "Search"
                            , Components.icon (Just Components.ProfilePeek) 40 40
                            ]
                        ]
                    ]
                ]
            ]
        ]


searchResults : Model -> Html Msg
searchResults model =
    case model.response of
        RemoteData.NotAsked ->
            Html.text ""

        RemoteData.Loading ->
            Html.text ""

        RemoteData.Success response ->
            Html.div
                [ style "display" "flex"
                , style "flex-direction" "column"
                , style "align-items" "center"
                , style "justify-content" "center"
                , style "gap" "20px"
                ]
                [ faceitComponent response.faceitData
                , linkList response.sites
                ]

        RemoteData.Failure error ->
            Html.text (errorToString error)


linkList : List Site -> Html msg
linkList sites =
    Html.div
        [ style "display" "flex"
        , style "align-items" "center"
        , style "justify-content" "center"
        , style "gap" "20px"
        ]
        (sites
            |> List.map
                (\site ->
                    Components.link site.url (Components.icon (Components.stringToIconType site.title) 40 40)
                )
        )


faceitComponent : Maybe API.FaceitData -> Html msg
faceitComponent faceitData =
    case faceitData of
        Nothing ->
            Html.text ""

        Just data ->
            Html.div
                [ style "display" "flex"
                , style "flex-direction" "column"
                , style "align-items" "center"
                , style "justify-content" "center"
                , style "gap" "12px"
                ]
                [ Html.img
                    [ Html.Attributes.src
                        (if String.isEmpty data.avatar then
                            API.assetUrl ++ "/icons/faceit/default-avatar.svg"

                         else
                            data.avatar
                        )
                    , Html.Attributes.alt "Faceit Avatar"
                    , style "width" "100px"
                    , style "height" "100px"
                    ]
                    []
                , Html.div
                    [ style "display" "flex", style "gap" "8px", style "align-items" "center" ]
                    [ Html.img [ Html.Attributes.alt <| "Country: " ++ String.toUpper data.country, Html.Attributes.src ("https://flagsapi.com/" ++ String.toUpper data.country ++ "/flat/24.png") ] []
                    , Html.p [ style "color" "white" ] [ Html.text data.nickname ]
                    ]
                , Html.div
                    [ style "display" "flex", style "align-items" "center", style "gap" "10px" ]
                    [ Html.img
                        [ Html.Attributes.src (API.assetUrl ++ "/icons/faceit/level" ++ String.fromInt data.level ++ ".svg")
                        , Html.Attributes.alt "Faceit Level"
                        , style "width" "30px"
                        , style "height" "30px"
                        ]
                        []
                    , Html.p [ style "color" "white" ] [ Html.text <| String.fromInt data.elo ]
                    ]
                ]


errorToString : Http.Error -> String
errorToString err =
    case err of
        Timeout ->
            "Timeout exceeded"

        NetworkError ->
            "Network error"

        BadStatus resp ->
            String.fromInt resp

        BadBody text ->
            "Unexpected response from api: " ++ text

        BadUrl url ->
            "Malformed url: " ++ url


buyMeACoffee : Html Msg
buyMeACoffee =
    Html.a
        [ Html.Attributes.href "https://www.buymeacoffee.com/mstruebing"
        , Html.Attributes.target "_blank"
        , Html.Attributes.style "margin-right" "40px"
        ]
        [ Html.img
            [ Html.Attributes.src "https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png"
            , Html.Attributes.alt "Buy Me A Coffee"
            , Html.Attributes.height 40
            , Html.Attributes.width 142
            ]
            []
        ]

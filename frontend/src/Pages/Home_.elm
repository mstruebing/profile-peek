module Pages.Home_ exposing (Model, Msg, page)

import API exposing (Response)
import Components exposing (IconType(..), footer)
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
import View exposing (View)


page : Shared.Model -> Route () -> Page Model Msg
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


init : Route () -> () -> ( Model, Effect Msg )
init _ () =
    ( { response = RemoteData.NotAsked, input = "" }
    , Effect.none
    )



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
            ( { model | response = RemoteData.Loading }, Effect.pushRoutePath <| Path.ALL_ { all_ = [ model.input ] } )

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
        [ header model
        , Html.div
            [ Html.Attributes.id "wrapper"
            , style "display" "flex"
            , style "flex-direction" "column"
            , style "justify-content" "space-between"
            , style "gap" "50px"
            , style "min-height" "48vh"
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
            []
        , footer
        ]
    }


header : Model -> Html Msg
header model =
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
        , searchBox model
        , buyMeACoffee
        ]


searchBox : Model -> Html Msg
searchBox model =
    Html.div
        [ style "display" "flex"
        , style "flex-direction" "column"
        , style "align-items" "center"
        , style "justify-content" "center"
        , style "flex-grow" "1"
        ]
        [ Html.form
            [ onSubmit Submit
            , style "width" "100%"
            ]
            [ Html.div
                [ style "display" "flex"
                , style "align-items" "center"
                , style "justify-content" "center"
                , style "flex-direction" "row"
                , style "width" "90%"
                , style "margin" "0 auto"
                , style "margin-left" "112px"
                , style "transform" "translateY(30vh)"
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
                , Html.div [ style "transform" "translateX(-112px)" ]
                    [ Html.button
                        [ disabled <|
                            String.isEmpty model.input
                                || (model.response == RemoteData.Loading)
                        , style "background-color" "#123"
                        , style "cursor" "pointer"
                        , style "border" "none"
                        , style "color" "white"
                        , style "border-radius" "22px"
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
                            , Components.icon (Just Components.ProfilePeek) 54 54
                            ]
                        ]
                    ]
                ]
            ]
        ]


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

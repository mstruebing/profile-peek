module Pages.Home_ exposing (Model, Msg, page)

import API exposing (responseDecoder)
import Components
import Html exposing (Html)
import Html.Attributes exposing (autofocus, class, disabled, placeholder, style)
import Html.Events exposing (onInput, onSubmit)
import Http exposing (Error(..))
import Page exposing (Page)
import Platform.Cmd as Cmd
import RemoteData exposing (RemoteData)
import Url exposing (percentEncode)
import View exposing (View)


type alias Response =
    { steam_id : String
    , sites : List Site
    }


type alias Site =
    { title : String, url : String }


page : Page Model Msg
page =
    Page.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- INIT


type alias Model =
    { input : String
    , response : RemoteData Http.Error Response
    }


init : ( Model, Cmd Msg )
init =
    ( { input = ""
      , response = RemoteData.NotAsked
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = NoOp
    | UpdateInput String
    | Submit
    | GotResult (Result Http.Error Response)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model
            , Cmd.none
            )

        UpdateInput input ->
            ( { model | input = input }, Cmd.none )

        Submit ->
            ( { model | response = RemoteData.Loading }, Http.get { url = "/player/" ++ percentEncode model.input, expect = Http.expectJson GotResult responseDecoder } )

        GotResult (Ok response) ->
            ( { model | response = RemoteData.Success response }, Cmd.none )

        GotResult (Err error) ->
            ( { model | response = RemoteData.Failure error }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title = "Finder"
    , body =
        [ header
        , Html.div
            [ Html.Attributes.id "wrapper"
            , style "display" "flex"
            , style "flex-direction" "column"
            , style "justify-content" "space-between"
            , style "margin-top"
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
        ]
    }


header : Html Msg
header =
    Html.header
        [ style "background-color" "rgb(34, 32, 32)"
        , style "width" "100vw"
        , style "position" "fixed"
        , style "top" "10px"
        ]
        [ Components.logo
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
            ]
            [ Html.div
                [ style "display" "flex"
                , style "align-items" "center"
                , style "justify-content" "center"
                , style "flex-direction" "column"
                , style "gap" "10px"
                ]
                [ Html.input
                    [ placeholder "Enter the Steam profile URL"
                    , autofocus True
                    , onInput UpdateInput
                    , style "width" "500px"
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
                        [ disabled
                            (String.isEmpty model.input)
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
                , style "align-items" "center"
                , style "justify-content" "center"
                , style "gap" "20px"
                ]
                (response.sites
                    |> List.map
                        (\site ->
                            Components.link site.url (Components.icon (Components.stringToIconType site.title) 40 40)
                        )
                )

        RemoteData.Failure error ->
            Html.text (errorToString error)


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

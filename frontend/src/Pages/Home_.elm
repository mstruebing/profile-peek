module Pages.Home_ exposing (Model, Msg, page)

import Html exposing (Html)
import Html.Attributes exposing (autofocus, class, disabled, href, placeholder, target)
import Html.Events exposing (onInput, onSubmit)
import Http exposing (Error(..))
import Json.Decode exposing (Decoder, field)
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
    ( { input = "", response = RemoteData.NotAsked }
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
        [ column [ class "gap" ]
            [ Html.form [ onSubmit Submit ]
                [ Html.input
                    [ disabled <| model.response == RemoteData.Loading
                    , placeholder "steam link"
                    , autofocus True
                    , onInput <| UpdateInput
                    ]
                    []
                , row [] [ Html.button [ disabled <| model.response == RemoteData.Loading ] [ Html.text "search" ] ]
                ]
            , case model.response of
                RemoteData.NotAsked ->
                    Html.text ""

                RemoteData.Loading ->
                    Html.div [ class "loading" ] [ Html.text "loading..." ]

                RemoteData.Success response ->
                    Html.div [] [ links response.sites ]

                RemoteData.Failure error ->
                    column [ class "error" ]
                        [ Html.div [] [ Html.text <| errorToString error ]
                        , Html.div [] [ Html.text "Try again" ]
                        ]
            ]
        ]
    }


links : List Site -> Html Msg
links sites =
    row [ class "link__row" ] <| List.map link sites


link : Site -> Html Msg
link { title, url } =
    column [ class "link" ] [ Html.a [ target "_blank", rel "noopener noreferrer", href url ] [ Html.text title ] ]


row : List (Html.Attribute msg) -> List (Html msg) -> Html msg
row attrs children =
    let
        attributes =
            class "row" :: attrs
    in
    Html.div attributes children


column : List (Html.Attribute msg) -> List (Html msg) -> Html msg
column attrs children =
    let
        attributes =
            class "column" :: attrs
    in
    Html.div attributes children


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


responseDecoder : Decoder Response
responseDecoder =
    Json.Decode.map2 Response
        (field "steam_id" Json.Decode.string)
        sitesDecoder


sitesDecoder : Decoder (List Site)
sitesDecoder =
    field "sites" (Json.Decode.list siteDecoder)


siteDecoder : Decoder Site
siteDecoder =
    Json.Decode.map2 Site
        (field "title" Json.Decode.string)
        (field "url" Json.Decode.string)

port module Main exposing (main)

import Browser
import Html exposing (Html)
import Html.Attributes exposing (href, rel, style, target)
import Http exposing (Error(..))
import Json.Decode exposing (Decoder, decodeString, field)
import Json.Encode
import RemoteData exposing (RemoteData)
import Url exposing (percentEncode)


port requestLocalStorageItem : String -> Cmd msg


port receiveLocalStorageItem : (String -> msg) -> Sub msg


port setLocalStorageItem : ( String, Json.Encode.Value ) -> Cmd msg


type alias Flags =
    { url : String }


type alias Response =
    { steam_id : String
    , sites : List Site
    }


type alias Site =
    { title : String, url : String }



-- MAIN


main : Program Flags Model Msg
main =
    Browser.element { init = init, update = update, subscriptions = subscriptions, view = view }



-- INIT


type alias Model =
    { url : String
    , response : RemoteData Http.Error Response
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { url = flags.url, response = RemoteData.NotAsked }
    , Cmd.batch
        [ Http.get
            { url = "https://finder.maex.me/player/" ++ percentEncode flags.url
            , expect = Http.expectJson GotResult responseDecoder
            }
        , requestLocalStorageItem flags.url
        ]
    )



-- UPDATE


type Msg
    = GotResult (Result Http.Error Response)
    | GotLocalStorageResult String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotResult (Ok response) ->
            ( { model | response = RemoteData.Success response }, setLocalStorageItem ( model.url, responseEncoder response ) )

        GotResult (Err error) ->
            ( { model | response = RemoteData.Failure error }, Cmd.none )

        GotLocalStorageResult value ->
            case decodeString responseDecoder value of
                Ok response ->
                    ( { model | response = RemoteData.Success response }, Cmd.none )

                Err _ ->
                    ( { model | response = RemoteData.Failure (BadBody value) }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    receiveLocalStorageItem GotLocalStorageResult



-- VIEW


view : Model -> Html Msg
view model =
    Html.div
        [ style "position" "fixed"
        , style "bottom" "10px"
        , style "left" "10px"
        ]
        [ case model.response of
            RemoteData.NotAsked ->
                Html.text ""

            RemoteData.Loading ->
                Html.text ""

            RemoteData.Success response ->
                Html.div [] [ links <| List.filter (\s -> s.title /= "Steam") response.sites ]

            RemoteData.Failure _ ->
                Html.text ""
        ]


links : List Site -> Html Msg
links sites =
    Html.div [] <| List.map link sites


link : Site -> Html Msg
link { title, url } =
    Html.div [] [ Html.a [ target "_blank", rel "noopener noreferrer", href url ] [ Html.text title ] ]


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


responseEncoder : Response -> Json.Encode.Value
responseEncoder response =
    Json.Encode.object
        [ ( "steam_id", Json.Encode.string response.steam_id )
        , ( "sites", Json.Encode.list siteEncoder response.sites )
        ]


siteEncoder : Site -> Json.Encode.Value
siteEncoder site =
    Json.Encode.object
        [ ( "title", Json.Encode.string site.title )
        , ( "url", Json.Encode.string site.url )
        ]

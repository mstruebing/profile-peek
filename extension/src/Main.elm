port module Main exposing (main)

import API exposing (Response, baseUrl, playerUrl, responseDecoder, responseEncoder)
import Browser
import Components exposing (icon, link, logoButton, sideBar, stringToIconType)
import Html exposing (Html)
import Http exposing (Error(..))
import Json.Decode exposing (decodeString)
import Json.Encode
import RemoteData exposing (RemoteData)
import Url exposing (percentEncode)


port requestLocalStorageItem : String -> Cmd msg


port receiveLocalStorageItem : (String -> msg) -> Sub msg


port setLocalStorageItem : ( String, Json.Encode.Value ) -> Cmd msg


type alias Flags =
    { url : String }



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
    ( { url = flags.url
      , response = RemoteData.NotAsked
      }
    , Cmd.batch
        [ Http.get
            { url = playerUrl ++ "/" ++ percentEncode flags.url
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
    case model.response of
        RemoteData.NotAsked ->
            Html.text ""

        RemoteData.Loading ->
            Html.text ""

        RemoteData.Success response ->
            sideBar <| link baseUrl logoButton :: responseToLinks response

        RemoteData.Failure _ ->
            Html.text ""


responseToLinks : Response -> List (Html msg)
responseToLinks response =
    response.sites
        |> List.filter (\s -> s.title /= "Steam")
        |> List.map
            (\site ->
                link site.url (icon (stringToIconType site.title) 20 20)
            )

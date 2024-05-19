defmodule Phoenix.LiveView.ErrorChannelTest do
  use ExUnit.Case, async: false
  import Phoenix.LiveView.TelemetryTestHelpers
  require Phoenix.ChannelTest
  @endpoint Phoenix.LiveViewTest.Endpoint

  setup_all do
    start_supervised!(Phoenix.PubSub.child_spec(name: Phoenix.LiveView.PubSub))
    :ok
  end

  test "telemetry events are emitted on successful message" do
    attach_telemetry([:phoenix, :live_view, :javascript])
    {:ok, socket} = Phoenix.ChannelTest.connect(Phoenix.LiveView.Socket, %{}, %{})
    assert {:ok, %{}, %{assigns: %{sourcemaps: %{"phoenix_live_view.cjs.js.map" => %{}}}} = socket} = Phoenix.ChannelTest.subscribe_and_join(socket, "lve:", %{})
    message = %{"measurement" => %{"duration" => 1}, "metadata" => %{"type" => "error", "message" => "some error", "stacktrace" => [[nil, %{"file" => "phoenix_live_view.cjs.js", "line" => 1, "col" => 2}]]}}
    Phoenix.ChannelTest.push(socket, "js-error", message)
    assert_receive {:event, [:phoenix, :live_view, :javascript, :exception], measurement, metadata}
    assert message["measurement"]["duration"] == measurement.duration
    assert message["metadata"]["message"] == metadata.message
    assert message["metadata"]["type"] == metadata.type
    assert [[nil, %{"col" => 2, "file" => "../../assets/js/phoenix_live_view/index.js", "line" => 0}]] == metadata.stacktrace
  end
end

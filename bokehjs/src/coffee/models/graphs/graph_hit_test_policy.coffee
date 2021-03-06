import {Model} from "../../model"
import {contains} from "core/util/array"
import {create_hit_test_result} from "core/hittest"


export class GraphHitTestPolicy extends Model

  do_selection: (geometry, graph_view, final, append) ->
    return false

  do_inspection: (geometry, graph_view, final, append) ->
    return false


export class NodesOnly extends GraphHitTestPolicy
  type: 'NodesOnly'

  _do: (geometry, graph_view, final, append) ->
    node_view = graph_view.node_view
    hit_test_result = node_view.glyph.hit_test(geometry)

    # glyphs that don't have hit-testing implemented will return null
    if hit_test_result == null
      return false

    @_node_selector.update(hit_test_result, final, append)

    return not @_node_selector.indices.is_empty()

  do_selection: (geometry, graph_view, final, append) ->
    @_node_selector = graph_view.node_view.model.data_source.selection_manager.selector
    did_hit = @_do(geometry, graph_view, final, append)
    graph_view.node_view.model.data_source.selected = @_node_selector.indices
    return did_hit

  do_inspection: (geometry, graph_view, final, append) ->
    @_node_selector = graph_view.node_view.model.data_source.selection_manager.inspectors[graph_view.model.id]
    did_hit = @_do(geometry, graph_view, final, append)
    graph_view.node_view.model.data_source.inspected = @_node_selector.indices
    return did_hit

export class NodesAndLinkedEdges extends GraphHitTestPolicy
  type: 'NodesAndLinkedEdges'

  _do: (geometry, graph_view, final, append) ->
    [node_view, edge_view] = [graph_view.node_view, graph_view.edge_view]
    hit_test_result = node_view.glyph.hit_test(geometry)

    # glyphs that don't have hit-testing implemented will return null
    if hit_test_result == null
      return false

    @_node_selector.update(hit_test_result, final, append)

    node_indices = (node_view.model.data_source.data.index[i] for i in hit_test_result["1d"].indices)
    edge_source = edge_view.model.data_source
    edge_indices = []
    for i in [0...edge_source.data.start.length]
      if contains(node_indices, edge_source.data.start[i]) or contains(node_indices, edge_source.data.end[i])
        edge_indices.push(i)

    linked_index = create_hit_test_result()
    for i in edge_indices
      linked_index["2d"].indices[i] = [0] #currently only supports 2-element multilines, so this is all of it

    @_edge_selector = edge_view.model.data_source.selection_manager.selector
    @_edge_selector.update(linked_index, final, append)

    return not @_node_selector.indices.is_empty()

  do_selection: (geometry, graph_view, final, append) ->
    @_node_selector = graph_view.node_view.model.data_source.selection_manager.selector
    @_edge_selector = graph_view.edge_view.model.data_source.selection_manager.selector

    did_hit = @_do(geometry, graph_view, final, append)

    graph_view.node_view.model.data_source.selected = @_node_selector.indices
    graph_view.edge_view.model.data_source.selected = @_edge_selector.indices
    graph_view.edge_view.model.data_source.select.emit()

    return did_hit

  do_inspection: (geometry, graph_view, final, append) ->
    @_node_selector = graph_view.node_view.model.data_source.selection_manager.inspectors[graph_view.model.id]
    @_edge_selector = graph_view.edge_view.model.data_source.selection_manager.inspectors[graph_view.edge_view.model.id]

    did_hit = @_do(geometry, graph_view, final, append)

    graph_view.node_view.model.data_source.inspected = @_node_selector.indices
    graph_view.edge_view.model.data_source.inspected = @_edge_selector.indices
    graph_view.edge_view.model.data_source.inspect.emit()

    return did_hit
